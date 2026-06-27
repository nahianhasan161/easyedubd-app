import 'package:easyedubd_app/core/providers/auth_notifier.dart';
import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/course_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const CourseListScreen(
      key: ValueKey('all_courses'),
    ),
    const CourseListScreen(
      key: ValueKey('my_courses'),
      enrolledOnly: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(supabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'All Courses' : 'My Courses',
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'All Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'My Courses',
          ),
        ],
      ),
    );
  }
}