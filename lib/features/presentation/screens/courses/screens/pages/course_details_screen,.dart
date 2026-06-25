import 'package:collection/collection.dart';
import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:easyedubd_app/shared/widgets/App_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourseDetailsScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return coursesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),

      data: (courses) {
        final course = courses.firstWhereOrNull((c) => c.id == courseId);

        if (course == null) {
          return const Scaffold(body: Center(child: Text('Course not found')));
        }

        return Scaffold(
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
                        return ListTile(
                          leading: const Icon(Icons.play_circle_fill),
                          title: Text(lesson.title),
                          subtitle: Text("${lesson.duration.inMinutes} min "),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                          ),
                          onTap: () {
                            context.push('/lesson/${lesson.videoId}');
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
  }
}
