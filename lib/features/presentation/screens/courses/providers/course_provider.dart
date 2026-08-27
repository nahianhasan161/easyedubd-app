import 'package:easyedubd_app/core/cache/cache_service.dart';
import 'package:easyedubd_app/core/cache/realtime_cache_invalidator.dart';
import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/core/network/retry.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/enrollment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository(Supabase.instance.client);
});

/// The set of course ids the current user is enrolled in.
///
/// This provider is designed to NEVER error. If the network call fails
/// (e.g. DNS not ready right after reconnecting), it returns the cached
/// set (or an empty set) and silently retries in the background. This
/// prevents the "My Courses" tab from showing a hard error when the
/// user is transitioning from offline to online.
final enrolledCourseIdsProvider = FutureProvider<Set<int>>((ref) async {
  // Outer safety net: the entire body is wrapped in try/catch so this
  // provider can NEVER enter an error state, regardless of what happens
  // below (unexpected throws from the cache layer, the repository, or
  // Riverpod's own internals). If anything goes wrong, we fall back to
  // an empty set so the UI stays alive.
  try {
    return await _loadEnrolledCourseIds(ref);
  } catch (_) {
    return <int>{};
  }
});

Future<Set<int>> _loadEnrolledCourseIds(Ref ref) async {
  final isOffline = ref.watch(isOfflineProvider);

  // Safely get the current user. In test environments where Supabase
  // isn't initialized, this would throw, so we catch and treat as
  // unauthenticated.
  String? userId;
  try {
    userId = Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    userId = null;
  }
  final cacheKey = userId == null ? null : CacheService.enrollmentKey(userId);

  // When offline, skip the network call entirely. Return cached data if
  // available, or an empty set.
  if (isOffline) {
    if (cacheKey != null) {
      final cached = CacheService.getEnrollment(cacheKey);
      if (cached != null) {
        try {
          return Set<int>.from((cached as List).cast<int>());
        } catch (_) {}
      }
    }
    return <int>{};
  }

  // Online: try the network call with backoff for transient errors.
  // If all retries fail, fall back to the cached set so the UI doesn't
  // show a hard error. The next lifecycle/connectivity event will
  // re-trigger this provider.
  try {
    final ids = await retryTransient(
      () => ref.read(enrollmentRepositoryProvider).getEnrolledCourseIds(),
      maxAttempts: 3,
      initialDelay: const Duration(seconds: 1),
    );
    return ids;
  } catch (_) {
    // Network call failed after retries. Return cached data if available
    // so the "My Courses" tab can still render cached courses.
    if (cacheKey != null) {
      final cached = CacheService.getEnrollment(cacheKey);
      if (cached != null) {
        try {
          return Set<int>.from((cached as List).cast<int>());
        } catch (_) {}
      }
    }
    return <int>{};
  }
}

Future<void> refreshStudentCourseCaches(WidgetRef ref) async {
  // Don't invalidate the course list providers directly here. Doing so
  // can throw "tried to rebuild NotifierProvider multiple times in the
  // same frame" when a widget that watches them is currently building
  // (e.g. the dashboard tab is being re-rendered after the admin screen
  // is popped). Instead, wipe the local cache and emit on the
  // `RealtimeCacheInvalidator.invalidations` stream. The
  // `AppLifecycleHandler._onCacheInvalidated` listener will then handle
  // the provider invalidation on the next frame, avoiding the conflict.
  await RealtimeCacheInvalidator.invalidateAllLocal();
}
