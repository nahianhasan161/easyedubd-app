import 'package:easyedubd_app/features/presentation/screens/admin/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/course_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:easyedubd_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourseEnrollmentScreen extends ConsumerStatefulWidget {
  const CourseEnrollmentScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final int courseId;
  final String courseTitle;

  @override
  ConsumerState<CourseEnrollmentScreen> createState() =>
      _CourseEnrollmentScreenState();
}

class _CourseEnrollmentScreenState extends ConsumerState<CourseEnrollmentScreen> {
  int _page = 1;
  final TextEditingController _searchController = TextEditingController();

  EnrollmentsQuery get _query => EnrollmentsQuery(
        page: _page,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        courseId: widget.courseId,
      );

  Future<void> _refresh() async {
    ref.invalidate(enrollmentsProvider(_query));
    await ref.read(enrollmentsProvider(_query).future);
  }

  void _applyFilters() {
    setState(() => _page = 1);
    ref.invalidate(enrollmentsProvider(_query));
  }

  Future<void> _showUserPicker() async {
    final searchController = TextEditingController();
    final selected = await showDialog<Profile>(
      context: context,
      builder: (dialogContext) => _UserPickerDialog(
        searchController: searchController,
        courseId: widget.courseId,
      ),
    );

    if (selected != null && mounted) {
      try {
        await ref
            .read(adminCourseRepositoryProvider)
            .enrollUser(profileId: selected.id, courseId: widget.courseId);
        ref.invalidate(enrollmentsProvider(_query));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${selected.fullName ?? 'User'} enrolled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not enroll user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeEnrollment(int enrollmentId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Enrollment',
      content: 'Are you sure you want to remove this user from the course?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(adminCourseRepositoryProvider)
          .removeEnrollment(enrollmentId);
      ref.invalidate(enrollmentsProvider(_query));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove enrollment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final enrollmentsAsync = ref.watch(enrollmentsProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text('Enrollments · ${widget.courseTitle}')),
      body: !isAdmin
          ? const Center(
              child: Text(
                'You do not have permission to view this page.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name, email or phone',
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                          onChanged: (value) {
                            Future.delayed(
                              const Duration(milliseconds: 400),
                              () {
                                if (mounted &&
                                    _searchController.text == value) {
                                  _applyFilters();
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showUserPicker,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        tooltip: 'Enroll user',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: enrollmentsAsync.when(
                      loading: () => ListView(
                        children: const [
                          SizedBox(height: 40),
                          Center(child: CircularProgressIndicator()),
                        ],
                      ),
                       error: (e, _) => ListView(
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text('Error: $e'),
                                  const SizedBox(height: 20),
                                  FilledButton.icon(
                                    onPressed: _refresh,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      data: (page) {
                        if (page.items.isEmpty) {
                          return ListView(
                            children: const [
                              SizedBox(height: 40),
                              Center(
                                child: Text('No enrollments found.'),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: page.items.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final enrollment = page.items[index];
                                  final isActive = enrollment.status ==
                                          'active' &&
                                      enrollment.expiresAt
                                          .isAfter(DateTime.now());

                                  return ListTile(
                                    title: Text(enrollment.fullName?.isNotEmpty == true
                                        ? enrollment.fullName!
                                        : enrollment.profileId),
                                    subtitle: Text(
                                      [
                                        if (enrollment.email?.isNotEmpty == true)
                                          enrollment.email!,
                                        if (enrollment.phone?.isNotEmpty == true)
                                          enrollment.phone!,
                                      ].join(' · '),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Chip(
                                          label: Text(
                                            isActive
                                                ? 'Active'
                                                : 'Expired',
                                          ),
                                          labelPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 6),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: isActive
                                              ? Colors.green
                                                  .withValues(alpha: 0.15)
                                              : Colors.red
                                                  .withValues(alpha: 0.15),
                                          labelStyle: TextStyle(
                                            color: isActive
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () =>
                                              _removeEnrollment(enrollment.id),
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red),
                                          tooltip: 'Remove enrollment',
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            _EnrollmentPaginationBar(
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
                  ),
                ),
              ],
            ),
    );
  }
}

class _UserPickerDialog extends ConsumerStatefulWidget {
  const _UserPickerDialog({
    required this.searchController,
    required this.courseId,
  });

  final TextEditingController searchController;
  final int courseId;

  @override
  ConsumerState<_UserPickerDialog> createState() => _UserPickerDialogState();
}

class _UserPickerDialogState extends ConsumerState<_UserPickerDialog> {
  String _term = '';
  late final Future<List<String>> _enrolledIdsFuture;

  @override
  void initState() {
    super.initState();
    _enrolledIdsFuture = ref
        .read(adminCourseRepositoryProvider)
        .getEnrolledProfileIds(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userSearchProvider(_term));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, email or phone',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  Future.delayed(const Duration(milliseconds: 350), () {
                    if (mounted &&
                        widget.searchController.text == value) {
                      setState(() => _term = value);
                    }
                  });
                },
              ),
            ),
            Flexible(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userSearchProvider(_term));
                  await ref.read(userSearchProvider(_term).future);
                },
                child: usersAsync.when(
                  loading: () => ListView(
                    shrinkWrap: true,
                    children: const [
                      SizedBox(height: 24),
                      Center(child: CircularProgressIndicator()),
                    ],
                  ),
                  error: (e, _) => ListView(
                    shrinkWrap: true,
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.wifi_off_rounded, size: 36, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text('Error: $e'),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () {
                                  if (_term.isNotEmpty) {
                                    setState(() {});
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  data: (users) {
                    return FutureBuilder<List<String>>(
                      future: _enrolledIdsFuture,
                      builder: (context, snap) {
                        final enrolled = snap.data ?? const <String>[];
                        final filtered = users
                            .where((u) => !enrolled.contains(u.id))
                            .toList();

                        if (filtered.isEmpty) {
                          return ListView(
                            shrinkWrap: true,
                            children: const [
                              SizedBox(height: 24),
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No users found.'),
                              ),
                            ],
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            final name = user.fullName?.isNotEmpty == true
                                ? user.fullName!
                                : 'Unnamed user';
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(name),
                              subtitle: Text(
                                (user.email?.isNotEmpty == true ||
                                        user.phone?.isNotEmpty == true)
                                    ? [
                                        if (user.email?.isNotEmpty == true)
                                          user.email,
                                        if (user.phone?.isNotEmpty == true)
                                          user.phone,
                                      ].join(' · ')
                                    : user.id,
                              ),
                              onTap: () => Navigator.of(context).pop(user),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentPaginationBar extends StatelessWidget {
  const _EnrollmentPaginationBar({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final PaginatedEnrollments page;
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
