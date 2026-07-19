import 'lessons.dart'; // Ensure Lesson is imported

class Chapter {
  final String id;
  final String title;
  final String description;
  final int? position;
  final List<Lesson> lessons;

  const Chapter({
    required this.id,
    required this.title,
    required this.description,
    this.position,
    required this.lessons,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      position: json['position'] is int ? json['position'] as int : null,
      lessons: (json['lesson'] as List? ?? [])
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}