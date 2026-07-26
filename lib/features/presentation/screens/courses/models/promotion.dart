class Promotion {
  final int id;
  final String name;
  final String discountType;
  final double discountValue;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;

  const Promotion({
    required this.id,
    required this.name,
    required this.discountType,
    required this.discountValue,
    this.startsAt,
    this.endsAt,
    required this.isActive,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: (json['id'] as num).toInt(),
      name: json['name'] ?? '',
      discountType: json['discount_type'] ?? 'percentage',
      discountValue: (json['discount_value'] as num).toDouble(),
      startsAt: json['starts_at'] == null
          ? null
          : DateTime.tryParse(json['starts_at'].toString())?.toLocal(),
      endsAt: json['ends_at'] == null
          ? null
          : DateTime.tryParse(json['ends_at'].toString())?.toLocal(),
      isActive: json['is_active'] ?? true,
    );
  }

  bool isActiveFor(DateTime now) {
    if (!isActive) return false;
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  bool get isExpired {
    final now = DateTime.now();
    return endsAt != null && now.isAfter(endsAt!);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return startsAt != null && now.isBefore(startsAt!);
  }

  Duration? get timeRemaining {
    if (endsAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endsAt!)) return Duration.zero;
    return endsAt!.difference(now);
  }

  String get formattedStartDate =>
      startsAt != null ? _formatDateTime(startsAt!) : 'No start date';

  String get formattedEndDate =>
      endsAt != null ? _formatDateTime(endsAt!) : 'No end date';

  String get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining == null) return 'No end date';
    if (remaining == Duration.zero) return 'Expired';
    if (remaining.inDays > 0) return '${remaining.inDays} day${remaining.inDays == 1 ? '' : 's'} left';
    if (remaining.inHours > 0) return '${remaining.inHours} hour${remaining.inHours == 1 ? '' : 's'} left';
    if (remaining.inMinutes > 0) return '${remaining.inMinutes} minute${remaining.inMinutes == 1 ? '' : 's'} left';
    return 'Less than 1 minute left';
  }

  String get discountLabel {
    if (discountType == 'percentage') {
      return '$discountValue% off';
    }
    return '৳${discountValue.toStringAsFixed(0)} off';
  }

  double? discountedPrice(double originalPrice) {
    if (!isActiveFor(DateTime.now())) return null;
    if (discountType == 'percentage') {
      final percent = discountValue / 100;
      return originalPrice * (1 - percent);
    }
    final fixed = discountValue;
    return originalPrice - fixed > 0 ? originalPrice - fixed : 0;
  }

  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final dateStr =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final timeStr =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }
}
