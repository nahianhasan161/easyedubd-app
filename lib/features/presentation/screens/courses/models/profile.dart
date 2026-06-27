class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final String? currentLevel;
  final String? institute;
  final String? faculty;
  final String? department;
  final String? session;
  final String? currentYear;

  const Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.createdAt,
    this.currentLevel,
    this.institute,
    this.faculty,
    this.department,
    this.session,
    this.currentYear,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      currentLevel: json['current_level'] as String?,
      institute: json['institute'] as String?,
      faculty: json['faculty'] as String?,
      department: json['department'] as String?,
      session: json['sesson'] as String?, // Matches your DB column name
      currentYear: json['current_year'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'current_level': currentLevel,
      'institute': institute,
      'faculty': faculty,
      'department': department,
      'sesson': session, // Matches your DB column name
      'current_year': currentYear,
    };
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    DateTime? createdAt,
    String? currentLevel,
    String? institute,
    String? faculty,
    String? department,
    String? session,
    String? currentYear,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      currentLevel: currentLevel ?? this.currentLevel,
      institute: institute ?? this.institute,
      faculty: faculty ?? this.faculty,
      department: department ?? this.department,
      session: session ?? this.session,
      currentYear: currentYear ?? this.currentYear,
    );
  }
}