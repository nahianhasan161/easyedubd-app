import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/shared/widgets/App_cached_image.dart';
import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const CourseCard({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: /*  Image.network(
                course.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ), */ AppCachedImage(
                url: course.imageUrl,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // DESCRIPTION
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // META INFO
                  /*  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Chapters: ${course.totalChapters}"),
                      Text("Lessons: ${course.totalLessons}"),
                    ],
                  ), */
                  const SizedBox(height: 10),

                  // PROGRESS BAR
                  LinearProgressIndicator(
                    value: course.progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${(course.progress * 100).toInt()}% completed",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
