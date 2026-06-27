class Enrollment {
  final int id;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? courseId;
  final int? bundleId;
  final String profileId;

  const Enrollment({
    required this.id,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.updatedAt,
    this.courseId,
    this.bundleId,
    required this.profileId,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'active',
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      courseId: json['course_id'] as int?,
      bundleId: json['bundle_id'] as int?,
      profileId: json['profile_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'course_id': courseId,
      'bundle_id': bundleId,
      'profile_id': profileId,
    };
  }

  bool get isActive =>
      status == 'active' && expiresAt.isAfter(DateTime.now());
}