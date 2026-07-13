import 'package:easyedubd_app/core/providers/router_provider.dart';
import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:easyedubd_app/core/startup/startup_controller.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/course_list_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_details_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/lesson_player.dart';
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

import 'package:easyedubd_app/shared/widgets/youtube_player.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyedubd_app/core/startup/startup_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  debugPrint("🔥 NEW GOROUTER CREATED");
  // 1. Watch the listenable so the router reacts to changes
  final listenable = ref.watch(authListenable);

  final supabase = ref.read(supabaseProvider);
  final startupState = ref.watch(startupProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable, // <---
    redirect: (context, state) {
      debugPrint(
        'REDIRECT: location=${state.matchedLocation}, '
        'startup=${startupState.value}',
      );
      final session = supabase.auth.currentSession;

      // Enforce admin-only access to /admin/* routes. While the UI menus
      // already hide these entries, this guard prevents a non-admin from
      // reaching them via deep links. Only acts once the profile is loaded
      // to avoid bouncing admins during the initial load.
      if (state.matchedLocation.startsWith('/admin')) {
        final profileState = ref.read(currentProfileProvider);
        final isAdmin = !profileState.isLoading &&
            profileState.value?.role?.toLowerCase() == 'admin';
        if (!isAdmin) return '/dashboard';
      }

      // Not logged in
      if (session == null) {
        final onboarding = ref.watch(onboardingCompletedProvider);

        return onboarding.when(
          loading: () => null,
          error: (_, __) =>
              state.matchedLocation != '/' ? '/' : null,
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

      /*  final startup = ref.read(startupProvider); */

      return startupState.when(
        loading: () => null,

        error: (_, __) => '/',

        data: (status) {
          switch (status) {
            case AppStartupState.authenticated:
              final publicRoutes = {'/', '/splash'};

              if (publicRoutes.contains(state.matchedLocation)) {
                return '/dashboard';
              }

              return null;

            case AppStartupState.pendingDevice:
              return state.matchedLocation == '/device-pending'
                  ? null
                  : '/device-pending';

            case AppStartupState.blockedDevice:
              return state.matchedLocation == '/device-blocked'
                  ? null
                  : '/device-blocked';

            case AppStartupState.unauthenticated:
              return '/';

            case AppStartupState.loading:
              return '/splash';
          }
        },
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),

      /// Pending device approval
      GoRoute(
        path: '/device-pending',

        builder: (_, _) => const DevicePendingScreen(),
      ),

      /// Blocked device
      GoRoute(
        path: '/device-blocked',

        builder: (_, _) => const DeviceBlockedScreen(),
      ),
      GoRoute(
        path: '/dashboard',

        builder: (context, state) => const DashboardScreen(),
      ),

      GoRoute(
        path: '/courses',

        builder: (context, state) => const CourseListScreen(),
      ),

      // ✅ Course details
      GoRoute(
        path: '/course/:courseId',

        builder: (context, state) {
          final courseId = int.parse(state.pathParameters['courseId']!);

          return CourseDetailsScreen(courseId: courseId);
        },
      ),

      // ✅ Lesson player (IMPORTANT FIXED DESIGN)
      GoRoute(
        path: '/lesson/:videoId',

        builder: (context, state) {
          final videoId = state.pathParameters['videoId'] ?? '';
          final title = state.extra as String?;
          return LessonPlayer(videoId: videoId, title: title ?? '');
        },
      ),

      GoRoute(
        path: '/youtubeplayer',

        builder: (context, state) => const YoutubePlayerScreen(),
      ),

      GoRoute(
        path: '/profile',

        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: '/admin/users',

        builder: (context, state) => const UserManagementScreen(),
      ),

      GoRoute(
        path: '/admin/users/:userId/devices',

        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final userName = state.extra as String? ?? 'User';

          return UserDevicesScreen(userId: userId, userName: userName);
        },
      ),

      GoRoute(
        path: '/onboarding',

        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});
