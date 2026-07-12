import 'package:easyedubd_app/features/presentation/screens/admin/user_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  int _page = 1;
  final Set<String> _busy = {};

  Future<void> _changeRole(Profile user) async {
    final isAdmin = (user.role ?? 'user').toLowerCase() == 'admin';
    final newRole = isAdmin ? 'user' : 'admin';

    setState(() => _busy.add(user.id));
    try {
      await ref.read(userRepositoryProvider).updateRole(user.id, newRole);
      ref.invalidate(usersProvider(_page));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.fullName ?? 'User'} is now ${newRole == 'admin' ? 'an admin' : 'a user'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final usersAsync = ref.watch(usersProvider(_page));

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: !isAdmin
          ? const Center(
              child: Text(
                'You do not have permission to view this page.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $e'),
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: page.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = page.items[index];
                          return _UserTile(
                            user: user,
                            busy: _busy.contains(user.id),
                            onToggleRole: () => _changeRole(user),
                            onTap: () => context.push(
                              '/admin/users/${user.id}/devices',
                              extra: user.fullName ?? user.id,
                            ),
                          );
                        },
                      ),
                    ),
                    _PaginationBar(
                      page: page,
                      onPrevious: _page > 1
                          ? () => setState(() => _page--)
                          : null,
                      onNext: _page < page.totalPages
                          ? () => setState(() => _page++)
                          : null,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.busy,
    required this.onToggleRole,
    this.onTap,
  });

  final Profile user;
  final bool busy;
  final VoidCallback onToggleRole;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAdmin = (user.role ?? 'user').toLowerCase() == 'admin';
    final name = user.fullName?.isNotEmpty == true
        ? user.fullName!
        : 'Unnamed user';
    final subtitle = [
      if (user.currentLevel?.isNotEmpty == true) user.currentLevel,
      if (user.institute?.isNotEmpty == true) user.institute,
    ].where((e) => e != null).join(' · ');

    final avatarUrl = user.avatarUrl;
    final imageProvider = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? NetworkImage(avatarUrl)
        : null;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: imageProvider,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: imageProvider == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(child: Text(name)),
          Chip(
            label: Text(isAdmin ? 'Admin' : 'User'),
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            visualDensity: VisualDensity.compact,
            backgroundColor: isAdmin
                ? Colors.deepPurple.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: isAdmin ? Colors.deepPurple : Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle)
          : const Text('No details'),
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FilledButton.tonal(
              onPressed: onToggleRole,
              child: Text(isAdmin ? 'Make User' : 'Make Admin'),
            ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final PaginatedUsers page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final totalPages = page.totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${page.start}–${page.end} of ${page.total}',
            style: const TextStyle(fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              Text('Page ${page.page} of ${totalPages == 0 ? 1 : totalPages}'),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
