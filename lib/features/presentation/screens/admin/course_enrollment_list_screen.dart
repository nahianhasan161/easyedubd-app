import 'package:easyedubd_app/features/presentation/screens/admin/course_management_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/course_management_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourseEnrollmentListScreen extends ConsumerStatefulWidget {
  const CourseEnrollmentListScreen({super.key});

  @override
  ConsumerState<CourseEnrollmentListScreen> createState() =>
      _CourseEnrollmentListScreenState();
}

class _CourseEnrollmentListScreenState
    extends ConsumerState<CourseEnrollmentListScreen> {
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
      appBar: AppBar(title: const Text('Course Enrollment')),
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
                                      '/admin/courses/${course.id}/enrollments',
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
                                    trailing: Chip(
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
                                  );
                                },
                              ),
                            ),
                            _CourseEnrollmentPaginationBar(
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

class _CourseEnrollmentPaginationBar extends StatelessWidget {
  const _CourseEnrollmentPaginationBar({
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
