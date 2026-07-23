import 'package:easyedubd_app/features/presentation/screens/admin/course_management_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/course_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_device.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_device_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:easyedubd_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.profile,
  });

  final String userId;
  final String userName;
  final Profile? profile;

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final profile = widget.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.person)),
            Tab(text: 'Devices', icon: Icon(Icons.devices)),
            Tab(text: 'Course Enrollments', icon: Icon(Icons.school)),
          ],
        ),
      ),
      body: !isAdmin
          ? const Center(
              child: Text(
                'You do not have permission to view this page.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                if (profile != null)
                  _ProfileTab(profile: profile)
                else
                  const Center(child: Text('No profile data available')),
                _DevicesTab(userId: widget.userId),
                _EnrollmentsTab(userId: widget.userId),
              ],
            ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (profile.fullName?.isNotEmpty == true)
        _InfoRow(label: 'Name', value: profile.fullName!),
      if (profile.email?.isNotEmpty == true)
        _InfoRow(label: 'Email', value: profile.email!),
      if (profile.phone?.isNotEmpty == true)
        _InfoRow(label: 'Phone', value: profile.phone!),
      _InfoRow(label: 'Role', value: profile.role ?? 'user'),
      if (profile.currentLevel?.isNotEmpty == true)
        _InfoRow(label: 'Level', value: profile.currentLevel!),
      if (profile.institute?.isNotEmpty == true)
        _InfoRow(label: 'Institute', value: profile.institute!),
      if (profile.department?.isNotEmpty == true)
        _InfoRow(label: 'Department', value: profile.department!),
      if (profile.session?.isNotEmpty == true)
        _InfoRow(label: 'Session', value: profile.session!),
      if (profile.currentYear?.isNotEmpty == true)
        _InfoRow(label: 'Year', value: profile.currentYear!),
      if (profile.gender?.isNotEmpty == true)
        _InfoRow(label: 'Gender', value: profile.gender!),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            profile.fullName?.isNotEmpty == true
                ? profile.fullName![0].toUpperCase()
                : 'U',
            style: const TextStyle(fontSize: 32, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        ...rows,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicesTab extends ConsumerWidget {
  const _DevicesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(userDevicesProvider(DevicesQuery(userId: userId, page: 1)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userDevicesProvider(DevicesQuery(userId: userId, page: 1)));
        await ref.read(userDevicesProvider(DevicesQuery(userId: userId, page: 1)).future);
      },
      child: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                      onPressed: () async {
                        ref.invalidate(userDevicesProvider(DevicesQuery(userId: userId, page: 1)));
                        await ref.read(userDevicesProvider(DevicesQuery(userId: userId, page: 1)).future);
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
        data: (page) {
          if (page.items.isEmpty) {
            return const Center(
              child: Text('No devices registered for this user.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: page.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final device = page.items[index];
              final title = device.deviceName?.isNotEmpty == true
                  ? device.deviceName!
                  : '${device.manufacturer ?? ''} ${device.model ?? ''}'
                      .trim()
                      .isEmpty
                  ? device.platform
                  : '${device.manufacturer} ${device.model}';
              final subtitle = [
                device.platform,
                if (device.osVersion?.isNotEmpty == true)
                  'OS ${device.osVersion}',
                if (device.appVersion?.isNotEmpty == true)
                  'App ${device.appVersion}',
              ].where((e) => e.isNotEmpty).join(' · ');

              final status = device.status;
              final (IconData icon, Color color, String label) = switch (status) {
                DeviceStatus.approved => (
                  Icons.verified_user,
                  Colors.green,
                  'Approved',
                ),
                DeviceStatus.pending => (
                  Icons.pending_outlined,
                  Colors.orange,
                  'Pending approval',
                ),
                DeviceStatus.blocked => (
                  Icons.block,
                  Colors.red,
                  'Blocked',
                ),
                _ => (
                  Icons.help_outline,
                  Colors.grey,
                  'Unknown',
                ),
              };

              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (subtitle.isNotEmpty) Text(subtitle),
                    Text(
                      'ID: ${device.installationId}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                trailing: DropdownButton<DeviceStatus>(
                  value: status,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: DeviceStatus.values.map((s) {
                    final (_, __, itemLabel) = switch (s) {
                      DeviceStatus.approved => (
                        Icons.verified_user,
                        Colors.green,
                        'Approved',
                      ),
                      DeviceStatus.pending => (
                        Icons.pending_outlined,
                        Colors.orange,
                        'Pending approval',
                      ),
                      DeviceStatus.blocked => (
                        Icons.block,
                        Colors.red,
                        'Blocked',
                      ),
                    };
                    return DropdownMenuItem(
                      key: Key('${device.id}_${s.name}'),
                      value: s,
                      child: Text(itemLabel),
                    );
                  }).toList(),
                  onChanged: (selected) {
                    if (selected == null || selected == status) return;
                    final adminId = ref.read(currentUserIdProvider);
                    if (adminId == null) return;

                    final approved = selected == DeviceStatus.approved;
                    final revokedAt = selected == DeviceStatus.blocked
                        ? DateTime.now()
                        : null;

                    ref.read(userRepositoryProvider).setDeviceApproved(
                          deviceId: device.id,
                          approved: approved,
                          adminId: adminId,
                          revokedAt: revokedAt,
                        ).then((_) {
                          ref.invalidate(userDevicesProvider(DevicesQuery(userId: userId, page: 1)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Device set to ${selected.name}')),
                          );
                        }).catchError((e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not update device: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EnrollmentsTab extends ConsumerWidget {
  const _EnrollmentsTab({required this.userId});

  final String userId;

  Future<void> _showAddCourseDialog(BuildContext context, WidgetRef ref) async {
    final searchController = TextEditingController();
    final courses = <Course>[];
    int page = 1;
    String? searchTerm;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int? enrollingId;

            Future<void> searchCourses([String? term]) async {
              if (isLoading) return;
              setDialogState(() {
                isLoading = true;
                page = 1;
                courses.clear();
                searchTerm = term?.trim().isEmpty == true ? null : term?.trim();
              });

              try {
                final result = await ref.read(
                  coursesProvider(CoursesQuery(page: 1, search: searchTerm)).future,
                );
                setDialogState(() {
                  courses.clear();
                  courses.addAll(result.items);
                  isLoading = false;
                });
              } catch (e) {
                setDialogState(() => isLoading = false);
              }
            }

            return AlertDialog(
              title: const Text('Add to Course'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search courses...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        Future.delayed(const Duration(milliseconds: 400), () {
                          if (searchController.text == value) {
                            searchCourses(value);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (isLoading)
                      const LinearProgressIndicator(minHeight: 2),
                    if (courses.isEmpty && !isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No courses found. Try a different search.'),
                      ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return ListTile(
                            title: Text(course.title),
                            subtitle: Text(
                              course.subject.isNotEmpty
                                  ? course.subject
                                  : 'Course ${course.id}',
                            ),
                            trailing: enrollingId == course.id
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                            enabled: enrollingId != course.id,
                            onTap: enrollingId == course.id
                                ? null
                                : () async {
                                    final selectedCourse = course;
                                    setDialogState(() {
                                      enrollingId = selectedCourse.id;
                                    });

                                    try {
                                      await ref
                                          .read(adminCourseRepositoryProvider)
                                          .enrollUser(
                                            profileId: userId,
                                            courseId: selectedCourse.id,
                                          );

                                      if (dialogContext.mounted) {
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Added to ${selectedCourse.title}',
                                            ),
                                          ),
                                        );
                                      }

                                      setDialogState(() {
                                        enrollingId = null;
                                      });

                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                    } catch (e) {
                                      setDialogState(() {
                                        enrollingId = null;
                                      });

                                      if (dialogContext.mounted) {
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to add: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeEnrollment(BuildContext context, WidgetRef ref, int enrollmentId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Enrollment',
      content: 'Are you sure you want to remove this user from the course?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(adminCourseRepositoryProvider)
          .removeEnrollment(enrollmentId);
      ref.invalidate(enrollmentsProvider(EnrollmentsQuery(page: 1, profileId: userId)));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment removed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(
      enrollmentsProvider(
        EnrollmentsQuery(page: 1, profileId: userId),
      ),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCourseDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add to Course'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(enrollmentsProvider(EnrollmentsQuery(page: 1, profileId: userId)));
          await ref.read(enrollmentsProvider(EnrollmentsQuery(page: 1, profileId: userId)).future);
        },
        child: enrollmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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
                        onPressed: () async {
                          ref.invalidate(enrollmentsProvider(EnrollmentsQuery(page: 1, profileId: userId)));
                          await ref.read(enrollmentsProvider(EnrollmentsQuery(page: 1, profileId: userId)).future);
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
          data: (page) {
            if (page.items.isEmpty) {
              return const Center(
                child: Text('No enrollments found for this user.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: page.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final enrollment = page.items[index];
                final isActive = enrollment.status == 'active' &&
                    enrollment.expiresAt.isAfter(DateTime.now());

                return ListTile(
                  title: Text(enrollment.courseTitle ?? 'Course ${enrollment.courseId ?? '?'}'),
                  subtitle: Text(
                    'Enrolled: ${enrollment.createdAt.toString().split(' ')[0]} · ${isActive ? 'Active' : 'Expired'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _removeEnrollment(context, ref, enrollment.id),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Remove enrollment',
                      ),
                      Chip(
                        label: Text(isActive ? 'Active' : 'Expired'),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: isActive
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
