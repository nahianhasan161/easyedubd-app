class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final String? currentLevel;
  final String? institute;
  final String? department;
  final String? session;
  final String? currentYear;
  final String? gender;
  final String? role;
  final String? email;
  final String? phone;

  const Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.createdAt,
    this.currentLevel,
    this.institute,
    this.department,
    this.session,
    this.currentYear,
    this.gender,
    this.role,
    this.email,
    this.phone,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final phoneValue = json['phone'];
    final phone = phoneValue is String
        ? phoneValue
        : phoneValue?.toString();

    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      currentLevel: json['current_level'] as String?,
      institute: json['institute'] as String?,
      department: json['department'] as String?,
      session: json['session'] as String?,
      currentYear: json['current_year'] as String?,
      gender: json['gender'] as String?,
      role: json['role'] as String?,
      email: json['email'] as String?,
      phone: phone,
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
      'department': department,
      'session': session,
      'current_year': currentYear,
      'gender': gender,
      'role': role,
      'email': email,
      'phone': phone,
    };
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'current_level': currentLevel,
      'institute': institute,
      'department': department,
      'session': session,
      'current_year': currentYear,
      'gender': gender,
      'role': role,
    };
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    DateTime? createdAt,
    String? currentLevel,
    String? institute,
    String? department,
    String? session,
    String? currentYear,
    String? gender,
    String? role,
    String? email,
    String? phone,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      currentLevel: currentLevel ?? this.currentLevel,
      institute: institute ?? this.institute,
      department: department ?? this.department,
      session: session ?? this.session,
      currentYear: currentYear ?? this.currentYear,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}