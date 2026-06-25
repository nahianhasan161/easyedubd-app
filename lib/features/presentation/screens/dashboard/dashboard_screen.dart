import 'package:easyedubd_app/core/providers/auth_notifier.dart';
import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/course_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.watch(supabaseProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        /* leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ), */
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              // This executes your AuthNotifier logic
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/videoplayer');
            },

            icon: const Icon(Icons.play_arrow),

            label: const Text('Omni'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/youtubeplayer');
            },

            icon: const Icon(Icons.play_arrow),

            label: const Text('yt'),
          ),
        ],
      ),
      body: const CourseListScreen(),
    );
  }
}
