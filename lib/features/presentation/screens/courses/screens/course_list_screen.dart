import 'package:easyedubd_app/features/presentation/screens/courses/data/dummy_courses.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_details_screen,.dart';

import 'package:easyedubd_app/features/presentation/screens/courses/widgets/course_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CourseListScreen extends StatelessWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: dummyCourses.length,
      itemBuilder: (context, index) {
        final course = dummyCourses[index];

        return CourseCard(
          course: course,
          onTap: () {
            context.push('/course/${course.id}');
          },
        );
      },
    );
  }
}
