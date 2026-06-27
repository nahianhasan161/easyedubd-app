class BundleCourse {
  final int id;
  final int bundleId;
  final int courseId;
  final DateTime createdAt;

  const BundleCourse({
    required this.id,
    required this.bundleId,
    required this.courseId,
    required this.createdAt,
  });

  factory BundleCourse.fromJson(Map<String, dynamic> json) {
    return BundleCourse(
      id: json['id'] as int,
      bundleId: json['bundle_id'] as int,
      courseId: json['course_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bundle_id': bundleId,
      'course_id': courseId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}