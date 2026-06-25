import 'lessons.dart'; // Ensure Lesson is imported

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

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      // Note: Ensure the key 'lesson' matches your Supabase query return
      lessons: (json['lesson'] as List? ?? [])
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}