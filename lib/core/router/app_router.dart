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
import 'package:easyedubd_app/features/presentation/screens/splash/splash_screen.dart';

import 'package:easyedubd_app/shared/widgets/youtube_player.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyedubd_app/core/startup/startup_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // 1. Watch the listenable so the router reacts to changes
  final listenable = ref.watch(authListenable);

  final supabase = ref.read(supabaseProvider);
  final startupState = ref.watch(startupProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable, // <---
    redirect: (context, state) {
      final session = supabase.auth.currentSession;

      // Not logged in
      if (session == null) {
        if (state.matchedLocation != '/') {
          return '/';
        }
        return null;
      }

      /*  final startup = ref.read(startupProvider); */

      return startupState.when(
        loading: () {
          if (state.matchedLocation != '/splash') {
            return '/splash';
          }
          return null;
        },

        error: (_, __) => '/',

        data: (status) {
          switch (status) {
            case AppStartupState.authenticated:
              return state.matchedLocation == '/dashboard'
                  ? null
                  : '/dashboard';

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
    ],
  );
});
