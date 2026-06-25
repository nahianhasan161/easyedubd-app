import 'chapter.dart'; // Ensure you import your chapter model

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

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      // This maps the nested Supabase 'Chapter' key
      chapters: (json['chapter'] as List? ?? [])
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}