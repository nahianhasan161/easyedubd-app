import 'dart:async';
import 'dart:developer' as developer;

import 'package:easyedubd_app/core/device/device_provider.dart';
import 'package:easyedubd_app/core/device/device_repository.dart';
import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/core/providers/course_provider.dart' as core_course;
import 'package:easyedubd_app/core/storage/local_cache_service.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart' as features_course;
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';
import '../providers/auth_provider.dart';

enum AppStartupState {
  loading,
  unauthenticated,
  authenticated,
  pendingDevice,
  blockedDevice,
  profileIncomplete,
}

class StartupController extends AsyncNotifier<AppStartupState> {
  late final SupabaseClient supabase;

  static const _deviceInfoTimeout = Duration(seconds: 4);
  static const _verifyDeviceTimeout = Duration(seconds: 4);
  static const _profileTimeout = Duration(seconds: 5);

  @override
  Future<AppStartupState> build() async {
    supabase = ref.read(supabaseProvider);

    final wasOffline = ref.read(isOffline);
    ref.listen<AsyncValue<bool>>(isOfflineProvider, (previous, next) {
      final was = previous?.value ?? wasOffline;
      final isNow = next.value ?? wasOffline;
      if (was && !isNow) {
        recheckOnResume();
      }
    });

    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      final nextEvent = next.value?.event;
      if (nextEvent == AuthChangeEvent.signedIn ||
          nextEvent == AuthChangeEvent.signedOut) {
        refresh();
      }
    });

    return initialize();
  }

  Future<AppStartupState> initialize() async {
    state = const AsyncLoading();

    try {
      final result = await _performStartupCheck().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Startup timed out after 15 seconds'),
      );

      state = AsyncData(result);

      if (result == AppStartupState.authenticated) {
        unawaited(_warmCaches());
      }

      unawaited(logCacheStatus());

      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return AppStartupState.unauthenticated;
    }
  }

  Future<AppStartupState> recheckOnResume() async {
    try {
      final result = await _performStartupCheck().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Resume check timed out after 15 seconds'),
      );

      if (state.value != result) {
        state = AsyncData(result);
      }

      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return AppStartupState.unauthenticated;
    }
  }

  Future<void> refresh() async {
    await initialize();
  }

  Future<void> _warmCaches() async {
    try {
      final session = supabase.auth.currentSession;
      if (session == null) return;

      final profileRepository = ref.read(profileRepositoryProvider);
      final enrollmentRepository = ref.read(features_course.enrollmentRepositoryProvider);
      final courseRepository = ref.read(core_course.courseRepositoryProvider);

      final profile = await profileRepository.getProfile(session.user.id);
      if (profile != null) {
        final cache = LocalCacheService();
        await cache.cacheProfile(profile.toJson());
      }

      final ids = await enrollmentRepository.getEnrolledCourseIds();

      final courses = await courseRepository.getCoursesByIds(
        ids.toList(),
        includeChapters: true,
      );

      final cache = LocalCacheService();
      await cache.cacheEnrolledCourses(courses.map((c) => c.toJson()).toList());

      if (ids.isNotEmpty) {
        try {
          final allCached = <Map<String, dynamic>>[];
          int offset = 0;
          const pageSize = 20;
          bool hasMore = true;

          while (hasMore) {
            final page = await courseRepository.getCourses(
              limit: pageSize,
              offset: offset,
              includeChapters: false,
            );
            if (page.isEmpty) {
              hasMore = false;
            } else {
              allCached.addAll(page.map((c) => c.toJson()));
              offset += pageSize;
              hasMore = page.length == pageSize;
            }
          }

          await cache.cacheCourses(allCached);
          developer.log(
            'Warmed general course cache with ${allCached.length} courses across all pages',
          );
        } catch (_) {
          // Best-effort cache of the general course list.
        }
      }
    } catch (e, st) {
      developer.log('Cache warming failed', error: e, stackTrace: st);
    }
  }

  Future<void> logCacheStatus() async {
    try {
      final cache = LocalCacheService();
      final courses = cache.getCachedCourses();
      final enrolled = cache.getCachedEnrolledCourses();
      final enrolledIds = cache.getCachedEnrolledCourseIds();
      developer.log(
        'Cache status: generalCourses=${courses.length}, enrolledCourses=${enrolled.length}, enrolledIds=${enrolledIds.length}',
      );
    } catch (e, st) {
      developer.log('Failed to log cache status', error: e, stackTrace: st);
    }
  }

  Future<void> preSeedCourseProvidersFromCache() async {
    try {
      final cache = LocalCacheService();
      final enrolledIds = cache.getCachedEnrolledCourseIds();
      final enrolledCourses = cache.getCachedEnrolledCourses();
      final generalCourses = cache.getCachedCourses();

      if (enrolledIds.isNotEmpty || generalCourses.isNotEmpty) {
        final allNotifier = ref.read(courseListProvider(false).notifier);
        final myNotifier = ref.read(courseListProvider(true).notifier);

        if (generalCourses.isNotEmpty) {
          final general = generalCourses.map((e) => Course.fromJson(e)).toList();
          allNotifier.state = CourseListState(
            courses: general,
            isInitialLoading: false,
            hasMore: false,
            error: null,
            enrolledCourseIds: enrolledIds,
          );
        }

        if (enrolledCourses.isNotEmpty) {
          final enrolled = enrolledCourses.map((e) => Course.fromJson(e)).toList();
          myNotifier.state = CourseListState(
            courses: enrolled,
            isInitialLoading: false,
            hasMore: false,
            error: null,
            enrolledCourseIds: enrolledIds,
          );
        }

        developer.log(
          'Pre-seeded course providers: general=${generalCourses.length}, enrolled=${enrolledCourses.length}, ids=${enrolledIds.length}',
        );
      }
    } catch (e, st) {
      developer.log('Failed to pre-seed course providers', error: e, stackTrace: st);
    }
  }

  void setState(AppStartupState value) {
    state = AsyncData(value);
  }

  Future<AppStartupState> _performStartupCheck() async {
    final session = supabase.auth.currentSession;

    if (ref.read(isOffline)) {
      final localAuth = await ref.read(localAuthProvider.future);
      final hasValidSession = session != null && !_isExpired(session);
      if (localAuth && hasValidSession) {
        await logCacheStatus();
        await preSeedCourseProvidersFromCache();
        return AppStartupState.authenticated;
      }
      return AppStartupState.unauthenticated;
    }

    if (session == null || _isExpired(session)) {
      return AppStartupState.unauthenticated;
    }

    // Online with session - verify device and profile. If any step fails
    // because the device is actually offline or the network is unreliable,
    // fall back to the cached authenticated experience so the user can still
    // reach the dashboard instead of getting stuck on splash.
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final deviceInfo = await deviceService.getDeviceInfo().timeout(
        _deviceInfoTimeout,
        onTimeout: () => throw TimeoutException('device info timeout'),
      );

      final deviceRepository = ref.read(deviceRepositoryProvider);
      DeviceVerificationResult deviceResult;
      try {
        deviceResult = await deviceRepository
            .verifyCurrentDevice(deviceInfo)
            .timeout(_verifyDeviceTimeout);
      } on TimeoutException {
        // Device verification timed out — likely offline. Fall back to the
        // cached authenticated experience so the user can still reach the
        // dashboard with cached courses.
        final localAuth = await ref.read(localAuthProvider.future);
        final hasValidSession = !_isExpired(session);
        if (localAuth && hasValidSession) {
          await logCacheStatus();
          await preSeedCourseProvidersFromCache();
          return AppStartupState.authenticated;
        }
        return AppStartupState.pendingDevice;
      }

      switch (deviceResult.status) {
        case DeviceVerificationStatus.revoked:
          return AppStartupState.blockedDevice;
        case DeviceVerificationStatus.pending:
          return AppStartupState.pendingDevice;
        case DeviceVerificationStatus.approved:
          break;
      }

      final profileRepository = ref.read(profileRepositoryProvider);
      Profile? profile;
      try {
        profile = await profileRepository
            .getProfile(session.user.id)
            .timeout(_profileTimeout, onTimeout: () => null);
      } catch (_) {
        profile = null;
      }

      final complete = _isProfileComplete(profile);
      if (!complete) {
        // Profile might be incomplete due to network failure. Fall back to
        // cached authenticated experience if we have local auth and session.
        final localAuth = await ref.read(localAuthProvider.future);
        final hasValidSession = !_isExpired(session);
        if (localAuth && hasValidSession) {
          await logCacheStatus();
          await preSeedCourseProvidersFromCache();
          return AppStartupState.authenticated;
        }
        return AppStartupState.profileIncomplete;
      }

      return AppStartupState.authenticated;
    } catch (e, st) {
      developer.log('Online startup check failed, falling back to cache', error: e, stackTrace: st);

      final localAuth = await ref.read(localAuthProvider.future);
      final hasValidSession = !_isExpired(session);
      if (localAuth && hasValidSession) {
        await logCacheStatus();
        await preSeedCourseProvidersFromCache();
        return AppStartupState.authenticated;
      }

      return AppStartupState.unauthenticated;
    }
  }

  bool _isProfileComplete(Profile? profile) {
    if (profile == null) return false;

    final fields = [
      profile.fullName,
      profile.phone,
      profile.currentLevel,
      profile.institute,
      profile.department,
      profile.session,
      profile.currentYear,
      profile.gender,
    ];

    return fields.every((field) => field != null && field.trim().isNotEmpty);
  }

  bool _isExpired(Session session) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(
      DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true),
    );
  }
}
