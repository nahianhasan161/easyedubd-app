import 'chapter.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double progress;
  final List<Chapter> chapters;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.progress,
    required this.chapters,
  });

  int get totalChapters => chapters.length;

  int get totalLessons =>
      chapters.fold(0, (sum, chapter) => sum + chapter.lessons.length);
}