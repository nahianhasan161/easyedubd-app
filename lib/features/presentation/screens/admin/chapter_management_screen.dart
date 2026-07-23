import 'package:easyedubd_app/features/presentation/screens/admin/course_management_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/course_management_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/chapter.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:easyedubd_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminChapterManagementScreen extends ConsumerStatefulWidget {
  const AdminChapterManagementScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final int courseId;
  final String courseTitle;

  @override
  ConsumerState<AdminChapterManagementScreen> createState() =>
      _AdminChapterManagementScreenState();
}

class _AdminChapterManagementScreenState
    extends ConsumerState<AdminChapterManagementScreen> {
  int _page = 1;
  final TextEditingController _searchController = TextEditingController();

  AdminChaptersQuery get _query => AdminChaptersQuery(
        courseId: widget.courseId,
        page: _page,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

  Future<void> _refresh() async {
    ref.invalidate(adminChaptersProvider(_query));
    await ref.read(adminChaptersProvider(_query).future);
  }

  void _applyFilters() {
    setState(() => _page = 1);
    ref.invalidate(adminChaptersProvider(_query));
  }

  Future<void> _showChapterDialog([Chapter? chapter]) async {
    final isEdit = chapter != null;
    final titleController = TextEditingController(text: chapter?.title ?? '');
    final descController = TextEditingController(text: chapter?.description ?? '');
    final positionController = TextEditingController(
      text: (chapter?.position ?? 0).toString(),
    );
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Chapter' : 'Create Chapter'),
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
                  final payload = {
                    'title': title,
                    'description': descController.text.trim(),
                    'course_id': widget.courseId,
                    'position': int.tryParse(positionController.text.trim()) ?? 0,
                  };

                  if (isEdit) {
                    await ref
                        .read(adminCourseManagementRepositoryProvider)
                        .updateChapter(int.parse(chapter!.id), payload);
                  } else {
                    await ref
                        .read(adminCourseManagementRepositoryProvider)
                        .createChapter(payload);
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
        SnackBar(content: Text(isEdit ? 'Chapter updated' : 'Chapter created')),
      );
    }
  }

  Future<void> _deleteChapter(int chapterId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Chapter',
      content: 'Are you sure you want to delete this chapter?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(adminCourseManagementRepositoryProvider)
          .deleteChapter(chapterId);
      ref.invalidate(adminChaptersProvider(_query));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapter deleted')),
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
    final chaptersAsync = ref.watch(adminChaptersProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text('Chapters · ${widget.courseTitle}')),
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
                            hintText: 'Search by chapter title',
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
                        onPressed: _showChapterDialog,
                        icon: const Icon(Icons.add),
                        tooltip: 'Create Chapter',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: chaptersAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
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
                          return const Center(
                            child: Text('No chapters found.'),
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
                                  final chapter = page.items[index];
                                  return ListTile(
                                    onTap: () => context.push(
                                      '/admin/courses/${widget.courseId}/chapters/${chapter.id}/lessons',
                                      extra: chapter.title,
                                    ),
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.deepPurple,
                                      child: Icon(Icons.menu_book, color: Colors.white),
                                    ),
                                    title: Text(
                                      chapter.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      chapter.description.isEmpty
                                          ? 'No description'
                                          : chapter.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _showChapterDialog(chapter),
                                          icon: const Icon(Icons.edit_outlined,
                                              color: Colors.blue),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _deleteChapter(int.parse(chapter.id)),
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
                            _AdminChapterPaginationBar(
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

class _AdminChapterPaginationBar extends StatelessWidget {
  const _AdminChapterPaginationBar({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final PaginatedAdminChapters page;
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
