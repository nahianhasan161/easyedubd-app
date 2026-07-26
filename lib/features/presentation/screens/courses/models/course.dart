import 'chapter.dart';
import 'promotion.dart';

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
  List<Promotion> promotions;
  final double? price;
  final int? position;

  Course({
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
    this.promotions = const [],
    this.price,
    this.position,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    final promotionsJson = json['promotions'] as List<dynamic>? ?? const [];
    final promotions = promotionsJson
        .map((e) => Promotion.fromJson(e as Map<String, dynamic>))
        .toList();

    return Course(
      id: (json['id'] as num).toInt(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'published',
      year: json['year'] ?? '',
      subject: json['subject'] ?? '',
      is_free: (json['is_free'] ?? true),
      chapters: (json['chapter'] as List? ?? [])
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      promotions: promotions,
      price: json['price'] == null
          ? null
          : ((json['price'] as num).toDouble() / 100),
      position: json['position'] == null
          ? null
          : (json['position'] as num).toInt(),
    );
  }

  double? get effectivePrice {
    if (is_free || price == null) return price;
    Promotion? best;
    for (final p in promotions) {
      if (best == null) {
        best = p;
        continue;
      }
      final bestDiscounted = best.discountedPrice(price!);
      final pDiscounted = p.discountedPrice(price!);
      if (pDiscounted != null &&
          (bestDiscounted == null || pDiscounted < bestDiscounted)) {
        best = p;
      }
    }
    return best?.discountedPrice(price!) ?? price;
  }

  double? get bestDiscountPercentage {
    if (is_free || price == null || price == 0) return null;
    final effective = effectivePrice;
    if (effective == null || effective == price) return null;
    return ((price! - effective) / price!) * 100;
  }
}
