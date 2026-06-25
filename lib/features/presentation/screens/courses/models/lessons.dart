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
    return Lesson(
      id: json['id'].toString(),

      title: json['title'] ?? '',

      description: json['description'] ?? '',

      videoId: json['videoId'] ?? '',

      duration: Duration(minutes: json['duration'] ?? 0),

      isCompleted: json['isCompleted'] ?? false,

      isLocked: json['isLock'] ?? false,
    );
  }
}
