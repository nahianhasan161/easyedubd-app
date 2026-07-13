class Lesson {
  final String id;
  final String title;
  final String description;

  final String videoId;
  final Duration duration;
  final bool isCompleted;
  final bool isLocked;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,

    required this.videoId,
    required this.duration,
    this.isCompleted = false,
    this.isLocked = false,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    // Supabase returns snake_case column names, so read both conventions.
    final videoId = (json['videoId'] ?? json['video_id'] ?? '').toString();
    final isCompleted =
        (json['isCompleted'] ?? json['is_completed'] ?? false) as bool;
    final isLocked = (json['isLock'] ?? json['is_locked'] ?? false) as bool;

    return Lesson(
      id: json['id'].toString(),

      title: json['title'] ?? '',

      description: json['description'] ?? '',

      videoId: videoId,

      duration: Duration(minutes: json['duration'] ?? 0),

      isCompleted: isCompleted,

      isLocked: isLocked,
    );
  }
}
