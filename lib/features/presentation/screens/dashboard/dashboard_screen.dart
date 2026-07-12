import 'package:easyedubd_app/core/providers/auth_notifier.dart';
import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/course_list_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const CourseListScreen(key: ValueKey('all_courses'), showAppBar: false),
    const CourseListScreen(
      key: ValueKey('my_courses'),
      enrolledOnly: true,
      showAppBar: false,
    ),
  ];

  Widget _buildProfileAvatar(AsyncValue<Profile?> profileAsync) {
    final profile = profileAsync.value;
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'User';
    final name = profile?.fullName?.isNotEmpty == true
        ? profile!.fullName!
        : email;
    final avatarUrl = profile?.avatarUrl;
    final imageProvider = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? NetworkImage(avatarUrl)
        : null;

    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(supabaseProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 170,
        leading: _buildProfileAvatar(profileAsync),
        title: Text(_currentIndex == 0 ? 'All Courses' : 'My Courses'),
        actions: [
          IconButton.filled(
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
            style: IconButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 180, 99, 93),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: IndexedStack(index: _currentIndex, children: _pages),

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
