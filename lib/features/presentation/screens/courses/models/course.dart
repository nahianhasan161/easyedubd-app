import 'chapter.dart'; // Ensure you import your chapter model

class Course {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final double progress;
  final bool is_free;
  final String status;
  final String year;
  final String subject;
  final List<Chapter> chapters;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.progress,
    required this.is_free,
    required this.status,
    required this.year,
    required this.subject,
    required this.chapters,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: (json['id'] as num).toInt(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      status: (json['status'] ?? 'published'),
      year: (json['year'] ?? ''),
      subject: (json['subject'] ?? ''),
      is_free: (json['is_free'] ?? true),
      // This maps the nested Supabase 'Chapter' key
      chapters: (json['chapter'] as List? ?? [])
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
