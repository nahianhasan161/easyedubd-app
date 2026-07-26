import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/lesson_player.dart';
import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:easyedubd_app/core/services/course_access_service.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/shared/widgets/App_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

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
    final courseAsync = ref.watch(courseByIdProvider(courseId));
    final enrolledCourseIdsAsync = ref.watch(enrolledCourseIdsProvider);
    final accessService = CourseAccessService();

    return courseAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),

      data: (course) {
        if (course == null) {
          return const Scaffold(body: Center(child: Text('Course not found')));
        }

        return enrolledCourseIdsAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
          data: (enrolledCourseIds) {
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
                  ref.invalidate(courseByIdProvider(courseId));
                  await ref.read(courseByIdProvider(courseId).future);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      automaticallyImplyLeading: false,
                      pinned: true,

                      flexibleSpace: FlexibleSpaceBar(
                        /*  title: Text(course.title), */
                        background: AppCachedImage(
                          url: course.imageUrl,

                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.description,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            _CourseProgressBar(course: course),
                          ],
                        ),
                      ),
                    ),

                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final chapter = course.chapters[index];

                        final totalMinutes = chapter.lessons.fold<int>(
                          0,
                          (sum, lesson) => sum + lesson.duration.inMinutes,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Card(
                            elevation: 2,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                childrenPadding: const EdgeInsets.only(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  child: Text(
                                    "${index + 1}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  chapter.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                subtitle: Text(
                                  "${chapter.lessons.length} Lessons • $totalMinutes mins",
                                ),
                                children: chapter.lessons.map((lesson) {
                                  final canWatch = accessService.canWatchLesson(
                                    isFree: course.is_free,
                                    hasCourseEnrollment: hasCourseEnrollment,
                                    hasBundleEnrollment: false,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        title: Text(
                                          lesson.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Row(
                                          children: [
                                            if (lesson.videoId.isNotEmpty) ...[
                                              Text(
                                                "${lesson.duration.inMinutes} min",
                                              ),
                                            ],
                                            if (canWatch && lesson.videoId.isEmpty) ...[
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
                                        leading: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: !canWatch
                                              ? Colors.red.shade100
                                              : lesson.videoId.isEmpty
                                                  ? Colors.orange.shade100
                                                  : Colors.green.shade100,
                                          child: Icon(
                                            !canWatch
                                                ? Icons.lock_rounded
                                                : lesson.videoId.isEmpty
                                                    ? Icons.schedule_rounded
                                                    : Icons.play_arrow_rounded,
                                            color: !canWatch
                                                ? Colors.red
                                                : lesson.videoId.isEmpty
                                                    ? Colors.orange
                                                    : Colors.green,
                                          ),
                                        ),
                                        trailing: Icon(
                                          canWatch
                                              ? lesson.videoId.isEmpty
                                                  ? Icons.hourglass_empty_rounded
                                                  : Icons.arrow_forward_ios_rounded
                                              : Icons.lock_outline_rounded,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                        onTap: () {
                                          if (!canWatch) {
                                            _showLockedDialog(context);
                                            return;
                                          }

                                          final previousChapter = index > 0
                                              ? ChapterNav(
                                                  id: course.chapters[index - 1].id,
                                                  title: course.chapters[index - 1].title,
                                                )
                                              : null;
                                          final nextChapter =
                                              index < course.chapters.length - 1
                                                  ? ChapterNav(
                                                      id: course.chapters[index + 1].id,
                                                      title: course.chapters[index + 1].title,
                                                    )
                                                  : null;

                                          final args = LessonPlayerArgs(
                                            title: lesson.title,
                                            courseId: course.id,
                                            chapterId: chapter.id,
                                            chapterTitle: chapter.title,
                                            lessonId: lesson.id,
                                            lessonsInChapter: chapter.lessons,
                                            allChapters: course.chapters,
                                            previousChapter: previousChapter,
                                            nextChapter: nextChapter,
                                          );

                                          if (lesson.videoId.isEmpty) {
                                            context.push(
                                              '/lesson',
                                              extra: args,
                                            );
                                          } else {
                                            context.push(
                                              '/lesson/${lesson.videoId}',
                                              extra: args,
                                            );
                                          }

                                          Future.delayed(const Duration(milliseconds: 300), () async {
                                            if (context.mounted) {
                                              ref.invalidate(courseByIdProvider(courseId));
                                              await ref.read(courseByIdProvider(courseId).future);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      }, childCount: course.chapters.length),
                    ),
                  ],
                ),
              ),

              floatingActionButton:
                  !hasCourseEnrollment &&
                      !course.is_free &&
                      course.price != null
                  ? FloatingActionButton.extended(
                      onPressed: () async {
                        // 1. Capture the event in PostHog
                        await Posthog().capture(
                          eventName: 'enroll_button_clicked',
                          properties: {
                            'course_title': course.title,
                            'original_price': course.price!.toStringAsFixed(0),
                            'offer_price': (course.price! * 0.8)
                                .toStringAsFixed(0),
                          },
                        );

                        final offerPrice = (course.price! * 0.8)
                            .toStringAsFixed(0);
                        final message = Uri.encodeComponent(
                          'Hello, I want to enroll in ${course.title}. Price: ৳$offerPrice',
                        );
                        launchUrl(
                          Uri.parse(
                            'https://wa.me/8801628424161?text=$message',
                          ),
                        );
                      },
                      backgroundColor: const Color(0xFFE6A817),
                      icon: const Icon(Icons.telegram, color: Colors.white),
                      label: Text(
                        'Enroll Now ৳${(course.price! * 0.8).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

class _CourseProgressBar extends StatelessWidget {
  final Course course;

  const _CourseProgressBar({required this.course});

  @override
  Widget build(BuildContext context) {
    final total = course.totalLessons;
    final completed = course.completedLessons;
    final percentage = course.completionPercentage;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.play_circle_outline, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Course Progress',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$completed of $total lessons',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 1.0
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(percentage * 100).toStringAsFixed(0)}% completed',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: percentage >= 1.0 ? Colors.green : theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
