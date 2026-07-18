import 'package:easyedubd_app/core/providers/router_provider.dart';
import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:easyedubd_app/core/startup/startup_controller.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/course_list_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_details_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/lesson_player.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/lesson_coming_soon_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/device_status/device_blocked_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/device_status/device_pending_screen.dart';

import 'package:easyedubd_app/features/presentation/screens/login/login_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/onboarding/onboarding_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_devices_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_management_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/splash/splash_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/settings/security_test_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/settings/notifications_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/settings/contact_screen.dart';

import 'package:easyedubd_app/shared/widgets/youtube_player.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyedubd_app/core/startup/startup_provider.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  debugPrint("🔥 NEW GOROUTER CREATED");
  // Watch ONLY the listenable so the router instance is created once and reacts
  // to auth/startup changes via refreshListenable (recreating the router would
  // reset it to initialLocation and flash the login screen on cold start).
  final listenable = ref.watch(authListenable);

  final supabase = ref.read(supabaseProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable, // <---
    redirect: (context, state) {
      // Read (not watch) the startup state at redirect time so a state change
      // re-runs the redirect via refreshListenable rather than rebuilding the
      // whole router.
      final startupState = ref.read(startupProvider);
      debugPrint(
        'REDIRECT: location=${state.matchedLocation}, '
        'startup=${startupState.value}',
      );
      // Diagnostic screen is reachable at any auth state for testing.
      if (state.matchedLocation == '/security-test') return null;
      final session = supabase.auth.currentSession;

      // Enforce admin-only access to /admin/* routes. While the UI menus
      // already hide these entries, this guard prevents a non-admin from
      // reaching them via deep links. Only acts once the profile is loaded
      // to avoid bouncing admins during the initial load.
      if (state.matchedLocation.startsWith('/admin')) {
        final profileState = ref.read(currentProfileProvider);
        final isAdmin =
            !profileState.isLoading &&
            profileState.value?.role?.toLowerCase() == 'admin';
        if (!isAdmin) return '/dashboard';
      }

      // Diagnostic / utility screens that should remain reachable even when
      // the device is pending or blocked.
      final publicRoutes = {'/security-test', '/notifications', '/contact'};

      // Startup drives the auth/device decision. It reads the (persisted)
      // session itself, so we rely on it instead of reading currentSession
      // directly here — that avoids a brief window on cold start where the
      // session hasn't finished restoring and the login screen flashes.
      //
      // While startup is still resolving (loading, or no value yet), keep the
      // user on /splash regardless of the target location so the login screen
      // never flashes. `value == null` covers the very first frames before the
      // AsyncNotifier has produced any data.
      if (startupState.isLoading || !startupState.hasValue) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      // If startup failed, fall back to the login screen rather than getting
      // stuck on the splash spinner.
      if (startupState.hasError) {
        return state.matchedLocation != '/' ? '/' : null;
      }

      final status = startupState.value!;

      // If startup resolved to unauthenticated, run the onboarding/login flow.
      if (status == AppStartupState.unauthenticated || session == null) {
        final onboarding = ref.read(onboardingCompletedProvider);

        return onboarding.when(
          // Still reading onboarding flag: wait on splash, don't flash login.
          loading: () => state.matchedLocation == '/splash' ? null : '/splash',
          error: (_, _) => state.matchedLocation != '/' ? '/' : null,
          data: (done) {
            if (!done) {
              return state.matchedLocation == '/onboarding'
                  ? null
                  : '/onboarding';
            }
            return state.matchedLocation != '/' ? '/' : null;
          },
        );
      }

      switch (status) {
        case AppStartupState.authenticated:
          final publicAuthRoutes = {'/', '/splash', '/onboarding'};

          if (publicAuthRoutes.contains(state.matchedLocation)) {
            return '/dashboard';
          }

          return null;

        case AppStartupState.pendingDevice:
          if (publicRoutes.contains(state.matchedLocation) ||
              state.matchedLocation == '/device-pending') {
            return null;
          }
          return '/device-pending';

        case AppStartupState.blockedDevice:
          if (publicRoutes.contains(state.matchedLocation) ||
              state.matchedLocation == '/device-blocked') {
            return null;
          }
          return '/device-blocked';

        case AppStartupState.unauthenticated:
          // Handled above.
          return '/';

        case AppStartupState.loading:
          return '/splash';
      }
    },
    observers: [PosthogObserver()],
    routes: [
      GoRoute(
        name: 'splash',
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),

      /// Pending device approval
      GoRoute(
        name: 'device-pending',
        path: '/device-pending',

        builder: (_, _) => const DevicePendingScreen(),
      ),

      /// Blocked device
      GoRoute(
        path: '/device-blocked',

        builder: (_, _) => const DeviceBlockedScreen(),
      ),
      GoRoute(
        name: 'dashboard',
        path: '/dashboard',

        builder: (context, state) => const DashboardScreen(),
      ),

      GoRoute(
        name: 'courses',
        path: '/courses',

        builder: (context, state) => const CourseListScreen(),
      ),

      // ✅ Course details
      GoRoute(
        name: 'course-details',
        path: '/course/:courseId',

        builder: (context, state) {
          final courseId = int.parse(state.pathParameters['courseId']!);

          return CourseDetailsScreen(courseId: courseId);
        },
      ),

      // ✅ Lesson player (IMPORTANT FIXED DESIGN)
      GoRoute(
        name: 'lesson-player',
        path: '/lesson/:videoId',

        builder: (context, state) {
          final videoId = state.pathParameters['videoId'] ?? '';
          final title = state.extra as String?;
          return LessonPlayer(videoId: videoId, title: title ?? '');
        },
      ),

      // ✅ Lesson coming soon (no video available)
      GoRoute(
        name: 'lesson-coming-soon',
        path: '/lesson',

        builder: (context, state) {
          final title = state.extra as String?;
          return LessonComingSoonScreen(title: title ?? '');
        },
      ),

      GoRoute(
        name: 'youtubeplayer',
        path: '/youtubeplayer',

        builder: (context, state) => const YoutubePlayerScreen(),
      ),

      GoRoute(
        name: 'profile',
        path: '/profile',

        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        name: 'user-management',
        path: '/admin/users',

        builder: (context, state) => const UserManagementScreen(),
      ),

      GoRoute(
        name: 'user-devices',
        path: '/admin/users/:userId/devices',

        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final userName = state.extra as String? ?? 'User';

          return UserDevicesScreen(userId: userId, userName: userName);
        },
      ),

      GoRoute(
        name: 'onboarding',
        path: '/onboarding',

        builder: (context, state) => const OnboardingScreen(),
      ),

      GoRoute(
        name: 'security-test',
        path: '/security-test',
        builder: (context, state) => const SecurityTestScreen(),
      ),

      GoRoute(
        name: 'notifications',
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      GoRoute(
        name: 'contact',
        path: '/contact',
        builder: (context, state) => const ContactScreen(),
      ),
    ],
  );
});
