import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:flutter/material.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourseDetailsScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);

    final course = courses.firstWhere((c) => c.id == courseId);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(course.title),
              background: Image.network(course.imageUrl, fit: BoxFit.cover),
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

          // Chapters
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
                    subtitle: Text("${lesson.duration.inMinutes} min"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),

                    onTap: () {
                      context.push('/lesson/IF1b0Wy4mpg'); //+ lesson.videoId
                    },
                  );
                }).toList(),
              );
            }, childCount: course.chapters.length),
          ),
        ],
      ),
    );
  }
}
