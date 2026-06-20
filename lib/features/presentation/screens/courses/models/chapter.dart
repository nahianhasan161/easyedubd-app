
import 'package:easyedubd_app/features/presentation/screens/courses/models/lessons.dart';

class Chapter {
  final String id;
  final String title;
  final String description;
  final List<Lesson> lessons;

  const Chapter({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
  });

  int get totalLessons => lessons.length;
}