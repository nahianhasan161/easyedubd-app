import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/chapter.dart';

import 'package:easyedubd_app/features/presentation/screens/courses/models/lessons.dart';

final List<Course> dummyCourses = [
  Course(
    id: '1',
    title: 'Flutter for Beginners',
    description: 'Learn Flutter from zero to hero',
    imageUrl: 'https://picsum.photos/400/200?1',
    progress: 0.3,
    chapters: [
      Chapter(
        id: 'c1',
        title: 'Chapter 1 - Basics',
        description: 'Introduction to Flutter',
        lessons: [
          Lesson(
            id: 'l1',
            title: 'Lesson 1 - What is Flutter?',
            description: 'Overview',
            videoUrl: 'url1',
            duration: const Duration(minutes: 5),
            videoId: 'IF1b0Wy4mpg',
          ),
          Lesson(
            id: 'l2',
            title: 'Lesson 2 - What is Flutter?',
            description: 'Overview',
            videoUrl: 'url1',
            duration: const Duration(minutes: 5),
            videoId: 'IF1b0Wy4mpg',
          ),
        ],
      ),
    ],
  ),
];
