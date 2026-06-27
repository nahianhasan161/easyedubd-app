class Bundle {
  final int id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String title;
  final String description;
  final String imageUrl;
  final bool isActive;

  const Bundle({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.isActive,
  });

  factory Bundle.fromJson(Map<String, dynamic> json) {
    return Bundle(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}