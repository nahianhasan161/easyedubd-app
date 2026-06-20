class Lesson {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String videoId;
  final Duration duration;
  final bool isCompleted;
  final bool isLocked;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.videoId,
    required this.duration,
    this.isCompleted = false,
    this.isLocked = false,
  });
}
