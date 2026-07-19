import 'package:easyedubd_app/features/presentation/screens/admin/course_management_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/course_management_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:easyedubd_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminCourseManagementScreen extends ConsumerStatefulWidget {
  const AdminCourseManagementScreen({super.key});

  @override
  ConsumerState<AdminCourseManagementScreen> createState() =>
      _AdminCourseManagementScreenState();
}

class _AdminCourseManagementScreenState
    extends ConsumerState<AdminCourseManagementScreen> {
  int _page = 1;
  final TextEditingController _searchController = TextEditingController();

  AdminCoursesQuery get _query => AdminCoursesQuery(
        page: _page,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

  Future<void> _refresh() async {
    ref.invalidate(adminCoursesProvider(_query));
    await ref.read(adminCoursesProvider(_query).future);
  }

  void _applyFilters() {
    setState(() => _page = 1);
    ref.invalidate(adminCoursesProvider(_query));
  }

  Future<void> _showCourseDialog([Course? course]) async {
    final isEdit = course != null;
    final titleController = TextEditingController(text: course?.title ?? '');
    final descController = TextEditingController(text: course?.description ?? '');
    final imageUrlController = TextEditingController(text: course?.imageUrl ?? '');
    final yearController = TextEditingController(text: course?.year ?? '');
    final subjectController = TextEditingController(text: course?.subject ?? '');
    final priceController = TextEditingController(
      text: course?.price == null ? '' : (course!.price! * 100).toInt().toString(),
    );
    final positionController = TextEditingController(
      text: (course?.position ?? 0).toString(),
    );
    bool isFree = course?.is_free ?? true;
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Course' : 'Create Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                TextField(
                  controller: yearController,
                  decoration: const InputDecoration(labelText: 'Year'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                Row(
                  children: [
                    Switch(
                      value: isFree,
                      onChanged: (value) {
                        setDialogState(() => isFree = value);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(isFree ? 'Free' : 'Paid'),
                  ],
                ),
                if (!isFree)
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price (cents)'),
                    keyboardType: TextInputType.number,
                  ),
                TextField(
                  controller: positionController,
                  decoration: const InputDecoration(labelText: 'Position'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  setDialogState(() => errorText = 'Title is required');
                  return;
                }

                try {
                  final price = int.tryParse(priceController.text.trim());
                  final payload = {
                    'title': title,
                    'description': descController.text.trim(),
                    'imageUrl': imageUrlController.text.trim(),
                    'year': yearController.text.trim(),
                    'subject': subjectController.text.trim(),
                    'is_free': isFree,
                    'price': isFree ? null : (price ?? 0).toDouble() / 100,
                    'position': int.tryParse(positionController.text.trim()) ?? 0,
                    'status': 'published',
                  };

                  if (isEdit) {
                    await ref
                        .read(adminCourseManagementRepositoryProvider)
                        .updateCourse(course!.id, payload);
                  } else {
                    await ref
                        .read(adminCourseManagementRepositoryProvider)
                        .createCourse(payload);
                  }
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  if (dialogContext.mounted) {
                    setDialogState(() => errorText = 'Error: $e');
                  }
                }
              },
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Course updated' : 'Course created')),
      );
    }
  }

  Future<void> _deleteCourse(int courseId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Course',
      content: 'Are you sure you want to delete this course?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(adminCourseManagementRepositoryProvider)
          .deleteCourse(courseId);
      ref.invalidate(adminCoursesProvider(_query));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _goToEnrollments(int courseId, String courseTitle) {
    context.push('/admin/courses/$courseId/enrollments', extra: courseTitle);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final coursesAsync = ref.watch(adminCoursesProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('Course Management')),
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
                            hintText: 'Search by course title',
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
                        onPressed: _showCourseDialog,
                        icon: const Icon(Icons.add),
                        tooltip: 'Create Course',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: coursesAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ListView(
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Error: $e'),
                            ),
                          ),
                        ],
                      ),
                      data: (page) {
                        if (page.items.isEmpty) {
                          return const Center(
                            child: Text('No courses found.'),
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
                                  final course = page.items[index];
                                  final badge = course.is_free
                                      ? 'FREE'
                                      : 'PAID';
                                  final badgeColor = course.is_free
                                      ? Colors.green
                                      : Colors.deepPurple;

                                  return ListTile(
                                    onTap: () => context.push(
                                      '/admin/courses/${course.id}/chapters',
                                      extra: course.title,
                                    ),
                                    leading: course.imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              course.imageUrl,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                width: 48,
                                                height: 48,
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                    Icons.menu_book_outlined),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                                Icons.menu_book_outlined),
                                          ),
                                    title: Text(
                                      course.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${course.year} Year · ${course.subject}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Chip(
                                          label: Text(badge),
                                          labelPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 6),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: badgeColor
                                              .withValues(alpha: 0.15),
                                          labelStyle: TextStyle(
                                            color: badgeColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _goToEnrollments(course.id, course.title),
                                          icon: const Icon(Icons.person_add_alt_1_rounded,
                                              color: Colors.green),
                                          tooltip: 'Enroll user',
                                        ),
                                        IconButton(
                                          onPressed: () => _showCourseDialog(course),
                                          icon: const Icon(Icons.edit_outlined,
                                              color: Colors.blue),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _deleteCourse(course.id),
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            _AdminCoursePaginationBar(
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

class _AdminCoursePaginationBar extends StatelessWidget {
  const _AdminCoursePaginationBar({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final PaginatedAdminCourses page;
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
