import 'package:easyedubd_app/core/providers/supabase_provider.dart';

import 'package:easyedubd_app/features/presentation/screens/courses/screens/course_list_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_details_screen,.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/lesson_player.dart';
import 'package:easyedubd_app/features/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/login/login_screen.dart';

import 'package:easyedubd_app/shared/widgets/omi_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return GoRouter(
    initialLocation: '/',

    redirect: (context, state) {
      final session = supabase.auth.currentSession;
      final loggingIn = state.matchedLocation == '/';
      /* if (session == null && !loggingIn) return '/';
      if (session != null && loggingIn) return '/dashboard'; */
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),

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
          final courseId = state.pathParameters['courseId'] ?? '';

          return CourseDetailsScreen(courseId: courseId);
        },
      ),

      // ✅ Lesson player (IMPORTANT FIXED DESIGN)
      GoRoute(
        path: '/lesson/:videoId',

        builder: (context, state) {
          final videoId = state.pathParameters['videoId'] ?? '';

          return LessonPlayer(videoId: videoId);
        },
      ),
      GoRoute(
        path: '/videoplayer',

        builder: (context, state) => const VideoScreen(),
      ),
    ],
  );
});
