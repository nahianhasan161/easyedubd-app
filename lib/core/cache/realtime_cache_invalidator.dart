import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cache_service.dart';

/// Lifecycle-driven cache invalidation for Supabase-backed data.
///
/// Polls Supabase for a `cache_version` row and invalidates the local
/// course / enrollment caches whenever the version on the server
/// increases. The check is **not** timer-driven — it runs only when the
/// user is actively engaged with the app (resume, tab change, route
/// return, connectivity change) or after an admin write. For a
/// rarely-changing dataset this is the right cadence: the cache stays
/// valid until the user does something that suggests they expect fresh
/// data. Idle users make zero background network calls.
///
/// The companion SQL is:
///
///   create table if not exists public.cache_version (
///     id int primary key default 1,
///     version bigint not null default 1,
///     updated_at timestamptz not null default now(),
///     constraint single_row check (id = 1)
///   );
///   insert into public.cache_version (id, version) values (1, 1)
///     on conflict (id) do nothing;
///
///   create or replace function public.bump_cache_version()
///   returns trigger as $$
///   begin
///     update public.cache_version
///        set version = version + 1, updated_at = now()
///      where id = 1;
///     return null;
///   end;
///   $$ language plpgsql security definer;
///
///   drop trigger if exists trg_bump_course on public.course;
///   create trigger trg_bump_course
///     after insert or update or delete on public.course
///     for each statement execute function public.bump_cache_version();
///
///   drop trigger if exists trg_bump_chapter on public.chapter;
///   create trigger trg_bump_chapter
///     after insert or update or delete on public.chapter
///     for each statement execute function public.bump_cache_version();
///
///   drop trigger if exists trg_bump_lesson on public.lesson;
///   create trigger trg_bump_lesson
///     after insert or update or delete on public.lesson
///     for each statement execute function public.bump_cache_version();
///
///   drop trigger if exists trg_bump_enrollment on public.enrollments;
///   create trigger trg_bump_enrollment
///     after insert or update or delete on public.enrollments
///     for each statement execute function public.bump_cache_version();
///
///   alter table public.cache_version enable row level security;
///   create policy "cache_version_read" on public.cache_version
///     for select using (true);
class RealtimeCacheInvalidator {
  static const String _table = 'cache_version';

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static bool _started = false;
  static bool _checking = false;
  static int _lastSeenVersion = 0;

  /// Stream that fires whenever any cache is invalidated.
  /// Use this to trigger Riverpod provider re-fetches.
  static Stream<void> get invalidations => _controller.stream;

  /// Start the invalidation service. Call this once after the user is
  /// authenticated (typically in `main()`). Safe to call multiple times;
  /// subsequent calls are no-ops.
  ///
  /// No timer is started. The version check runs only on lifecycle
  /// events (`checkNow()`) and after admin writes
  /// (`invalidateAllLocal()`). This is deliberate: the cache is the
  /// source of truth, and a rarely-changing dataset doesn't need
  /// background polling.
  static void start() {
    if (_started) return;
    _started = true;

    final saved = CacheService.getLastSeenCacheVersion();
    _lastSeenVersion = saved ?? 0;

    // One immediate check on startup so the first session doesn't have
    // to wait for a lifecycle event to discover server-side changes
    // that happened while the app was killed.
    unawaited(_checkSafely());
  }

  /// Run a single check right now. Call this from lifecycle hooks:
  /// - `AppLifecycleState.resumed` (app comes to foreground)
  /// - Tab change in the dashboard
  /// - `RouteAware.didPopNext` (coming back from a detail page)
  /// - Connectivity change (offline → online)
  ///
  /// No-op if a check is already in flight or the service hasn't been
  /// started yet.
  static void checkNow() {
    if (!_started) return;
    unawaited(_checkSafely());
  }

  /// Wipe the local course + enrollment caches and emit on the
  /// `invalidations` stream. Use this after a successful admin write so
  /// the admin's own device picks up the change immediately, without
  /// waiting for the next lifecycle event.
  static Future<void> invalidateAllLocal() async {
    await CacheService.invalidateAllCourses();
    await CacheService.invalidateAllEnrollments();
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  /// Stop the service. Call on logout. Currently a no-op since there's
  /// no timer, but kept for API stability and future-proofing.
  static Future<void> stop() async {
    _started = false;
  }

  static Future<void> dispose() async {
    await stop();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  static Future<void> _checkSafely() async {
    if (_checking) return;
    _checking = true;
    try {
      await _checkOnce();
    } catch (_) {
      // Network or permission errors are expected (offline / cold start).
      // The next lifecycle event will try again.
    } finally {
      _checking = false;
    }
  }

  static Future<void> _checkOnce() async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.every((r) => r == ConnectivityResult.none);
    if (isOffline) return;

    final supabase = Supabase.instance.client;
    final res = await supabase
        .from(_table)
        .select('version')
        .eq('id', 1)
        .maybeSingle();

    if (res == null) return;
    final raw = res['version'];
    final serverVersion = raw is int
        ? raw
        : (raw is num ? raw.toInt() : int.tryParse(raw.toString()) ?? 0);
    if (serverVersion <= 0) return;

    if (_lastSeenVersion == 0) {
      // First run: record the current version but do NOT invalidate the
      // local cache. This avoids wiping a valid cache on first install /
      // after upgrading the app, when the version may have already moved
      // past what was last cached.
      _lastSeenVersion = serverVersion;
      await CacheService.setLastSeenCacheVersion(serverVersion);
      return;
    }

    if (serverVersion > _lastSeenVersion) {
      _lastSeenVersion = serverVersion;
      await CacheService.setLastSeenCacheVersion(serverVersion);
      await CacheService.invalidateAllCourses();
      await CacheService.invalidateAllEnrollments();
      if (!_controller.isClosed) {
        _controller.add(null);
      }
    }
  }
}
