import 'package:easyedubd_app/core/providers/auth_notifier.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:easyedubd_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final profile = profileAsync.value;

    final name = profile?.fullName?.isNotEmpty == true
        ? profile!.fullName!
        : (email.isNotEmpty ? email : 'User');
    final avatarUrl = profile?.avatarUrl;
    final imageProvider = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? NetworkImage(avatarUrl)
        : null;
    final role = (profile?.role ?? 'user').toLowerCase() == 'admin'
        ? 'Admin'
        : 'User';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(name),
            accountEmail: Row(
              children: [
                Expanded(
                  child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: imageProvider,
              backgroundColor: Colors.white,
              child: imageProvider == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              final router = GoRouter.of(context);
              context.pop();
              router.go('/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: () {
              final router = GoRouter.of(context);
              context.pop();
              router.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.headset_mic_rounded),
            title: const Text('Contact'),
            onTap: () {
              context.pop();
              context.push('/contact');
            },
          ),
          if (isAdmin) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('User Management'),
              onTap: () {
                final router = GoRouter.of(context);
                context.pop();
                router.push('/admin/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Course Management'),
              onTap: () {
                final router = GoRouter.of(context);
                context.pop();
                router.push('/admin/course-management');
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Logout',
                content: 'Are you sure you want to log out?',
                confirmLabel: 'Logout',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                context.pop();
                ref.read(authControllerProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
