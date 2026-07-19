import 'package:easyedubd_app/features/presentation/screens/admin/course_management_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/course_management_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/lessons.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:easyedubd_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminLessonManagementScreen extends ConsumerStatefulWidget {
  const AdminLessonManagementScreen({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
    required this.courseId,
  });

  final int chapterId;
  final String chapterTitle;
  final int courseId;

  @override
  ConsumerState<AdminLessonManagementScreen> createState() =>
      _AdminLessonManagementScreenState();
}

class _AdminLessonManagementScreenState
    extends ConsumerState<AdminLessonManagementScreen> {
  int _page = 1;
  final TextEditingController _searchController = TextEditingController();

  AdminLessonsQuery get _query => AdminLessonsQuery(
        chapterId: widget.chapterId,
        page: _page,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

  Future<void> _refresh() async {
    ref.invalidate(adminLessonsProvider(_query));
    await ref.read(adminLessonsProvider(_query).future);
  }

  void _applyFilters() {
    setState(() => _page = 1);
    ref.invalidate(adminLessonsProvider(_query));
  }

  Future<void> _showLessonDialog([Lesson? lesson]) async {
    final isEdit = lesson != null;
    final titleController = TextEditingController(text: lesson?.title ?? '');
    final descController = TextEditingController(text: lesson?.description ?? '');
    final videoIdController = TextEditingController(text: lesson?.videoId ?? '');
    final durationController = TextEditingController(
      text: lesson?.duration.inMinutes.toString() ?? '0',
    );
    final positionController = TextEditingController(
      text: (lesson?.position ?? 0).toString(),
    );
    bool isLocked = lesson?.isLocked ?? true;
    bool isCompleted = lesson?.isCompleted ?? false;
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Lesson' : 'Create Lesson'),
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
                  controller: videoIdController,
                  decoration: const InputDecoration(labelText: 'Video ID'),
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: positionController,
                  decoration: const InputDecoration(labelText: 'Position'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Switch(
                      value: isLocked,
                      onChanged: (value) {
                        setDialogState(() => isLocked = value);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(isLocked ? 'Locked' : 'Unlocked'),
                  ],
                ),
                Row(
                  children: [
                    Switch(
                      value: isCompleted,
                      onChanged: (value) {
                        setDialogState(() => isCompleted = value);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(isCompleted ? 'Completed' : 'Not completed'),
                  ],
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
                  final duration = int.tryParse(durationController.text.trim());
                  final position = int.tryParse(positionController.text.trim());
                  final payload = {
                    'title': title,
                    'description': descController.text.trim(),
                    'videoId': videoIdController.text.trim(),
                    'duration': duration ?? 0,
                    'chapter_id': widget.chapterId,
                    'position': position ?? 0,
                    'isComplete': isCompleted,
                    'isLock': isLocked,
                  };

                  if (isEdit) {
                    await ref
                        .read(adminCourseManagementRepositoryProvider)
                        .updateLesson(int.parse(lesson!.id), payload);
                  } else {
                    await ref
                        .read(adminCourseManagementRepositoryProvider)
                        .createLesson(payload);
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
        SnackBar(content: Text(isEdit ? 'Lesson updated' : 'Lesson created')),
      );
    }
  }

  Future<void> _deleteLesson(int lessonId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Lesson',
      content: 'Are you sure you want to delete this lesson?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(adminCourseManagementRepositoryProvider)
          .deleteLesson(lessonId);
      ref.invalidate(adminLessonsProvider(_query));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson deleted')),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final lessonsAsync = ref.watch(adminLessonsProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text('Lessons · ${widget.chapterTitle}')),
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
                            hintText: 'Search by lesson title',
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
                        onPressed: _showLessonDialog,
                        icon: const Icon(Icons.add),
                        tooltip: 'Create Lesson',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: lessonsAsync.when(
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
                            child: Text('No lessons found.'),
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
                                  final lesson = page.items[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: lesson.isLocked
                                          ? Colors.grey
                                          : lesson.videoId.isEmpty
                                              ? Colors.orange
                                              : Colors.green,
                                      child: Icon(
                                        lesson.isLocked
                                            ? Icons.lock
                                            : lesson.videoId.isEmpty
                                                ? Icons.schedule_rounded
                                                : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      lesson.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Row(
                                      children: [
                                        if (lesson.videoId.isNotEmpty)
                                          Text(
                                            '${lesson.duration.inMinutes} min',
                                          ),
                                        if (lesson.videoId.isNotEmpty)
                                          const SizedBox(width: 6),
                                        Text(
                                          lesson.isCompleted ? 'Completed' : 'Not completed',
                                        ),
                                        if (lesson.videoId.isEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Coming Soon',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _showLessonDialog(lesson),
                                          icon: const Icon(Icons.edit_outlined,
                                              color: Colors.blue),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _deleteLesson(int.parse(lesson.id)),
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
                            _AdminLessonPaginationBar(
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

class _AdminLessonPaginationBar extends StatelessWidget {
  const _AdminLessonPaginationBar({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final PaginatedAdminLessons page;
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
