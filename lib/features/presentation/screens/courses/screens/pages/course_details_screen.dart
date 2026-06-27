import 'package:collection/collection.dart';
import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:easyedubd_app/core/services/course_access_service.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart';
import 'package:easyedubd_app/shared/widgets/App_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourseDetailsScreen extends ConsumerWidget {
  final int courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Locked Lesson"),
        content: const Text(
          "This lesson is locked. Please enroll in the course or bundle to access it.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final enrolledCourseIdsAsync = ref.watch(enrolledCourseIdsProvider);
    final accessService = CourseAccessService();

    return coursesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),

      data: (courses) {
        return enrolledCourseIdsAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
          data: (enrolledCourseIds) {
            final course = courses.firstWhereOrNull((c) => c.id == courseId);

            if (course == null) {
              return const Scaffold(
                body: Center(child: Text('Course not found')),
              );
            }

            // TEMP (replace later with Supabase)
            final hasCourseEnrollment = enrolledCourseIds.contains(course.id);

            return Scaffold(
              appBar: AppBar(
                title: Text(course.title),

                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),

                  onPressed: () => context.pop(),
                ),
              ),

              body: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(coursesProvider);
                  await ref.read(coursesProvider.future);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      automaticallyImplyLeading: false,
                      pinned: true,

                      

                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(course.title),

                        background: AppCachedImage(
                          url: course.imageUrl,

                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          course.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final chapter = course.chapters[index];

                        return ExpansionTile(
                          title: Text(chapter.title),
                          subtitle: Text(chapter.description),

                          children: chapter.lessons.map((lesson) {
                            final canWatch = accessService.canWatchLesson(
                              isFree: course.is_free,
                              hasCourseEnrollment: hasCourseEnrollment,
                              hasBundleEnrollment: false,
                            );

                            return ListTile(
                              leading: Icon(
                                canWatch ? Icons.lock_open : Icons.lock,
                                color: canWatch ? Colors.green : Colors.red,
                              ),
                              title: Text(lesson.title),
                              subtitle: Text(
                                "${lesson.duration.inMinutes} min",
                              ),
                              trailing: Icon(
                                canWatch ? Icons.play_circle_fill : Icons.lock,
                                size: 14,
                              ),
                              onTap: () {
                                if (!canWatch) {
                                  _showLockedDialog(context);
                                  return;
                                }

                                context.push(
                                  '/lesson/${lesson.videoId}',
                                  extra: lesson.title,
                                );
                              },
                            );
                          }).toList(),
                        );
                      }, childCount: course.chapters.length),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
