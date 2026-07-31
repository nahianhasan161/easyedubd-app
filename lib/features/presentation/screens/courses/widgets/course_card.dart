import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/shared/widgets/App_cached_image.dart';
import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final bool isEnrolled;
  final VoidCallback? onEnroll;
  final bool isCompact;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.isEnrolled = false,
    this.onEnroll,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFree = course.is_free;
    final originalPrice = course.price;
    final effectivePrice = course.effectivePrice;
    final hasDiscount =
        effectivePrice != null &&
        originalPrice != null &&
        effectivePrice < originalPrice;
    final discountPercent = course.bestDiscountPercentage;

    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      height: 1.25,
    );
    final titleCompactStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
      height: 1.2,
      fontSize: 13,
    );

    final bodyPadding = isCompact
        ? const EdgeInsets.fromLTRB(8, 6, 8, 8)
        : const EdgeInsets.fromLTRB(14, 12, 14, 14);
    final titleStyleFinal = isCompact ? titleCompactStyle : titleStyle;

    return Card(
      margin: EdgeInsets.symmetric(vertical: isCompact ? 2 : 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE + BADGES
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppCachedImage(
                    url: course.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),

                // Subtle gradient at the top so badges stay readable.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: isCompact ? 40 : 64,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // BADGE (top-left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: _Pill(
                    gradient: isEnrolled || isFree
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFFFF1B8), Color(0xFFE6A817)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isEnrolled
                        ? Colors.blue
                        : isFree
                        ? Colors.green
                        : null,
                    icon: isEnrolled
                        ? Icons.check_circle
                        : isFree
                        ? Icons.check_circle
                        : Icons.workspace_premium_outlined,
                    label: isEnrolled
                        ? 'ENROLLED'
                        : isFree
                        ? 'FREE'
                        : 'PREMIUM',
                    gold: !isEnrolled && !isFree,
                    isCompact: isCompact,
                  ),
                ),

                // DISCOUNT BADGE (bottom-left of image)
                if (hasDiscount && discountPercent != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 5 : 10,
                        vertical: isCompact ? 3 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '-${discountPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: isCompact ? 10 : 16,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // BODY
            Padding(
              padding: bodyPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    course.title,
                    style: titleStyleFinal,
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: isCompact ? 4 : 10),

                  // TAGS (year + subject, one line)
                  Row(
                    children: [
                      if (course.year.trim().isNotEmpty)
                        _Tag(
                          text: '${course.year} Year',
                          isCompact: isCompact,
                        ),
                      if (course.year.trim().isNotEmpty &&
                          course.subject.trim().isNotEmpty)
                        SizedBox(width: isCompact ? 4 : 8),
                      if (course.subject.trim().isNotEmpty)
                        _Tag(
                          text: course.subject,
                          isCompact: isCompact,
                        ),
                    ],
                  ),

                  // DETAILS (left) + PRICE (right)
                  if (!isFree && !isEnrolled && originalPrice != null)
                    Padding(
                      padding: EdgeInsets.only(top: isCompact ? 2 : 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (onEnroll != null)
                            Text(
                              'Details',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: isCompact ? 9 : 12,
                              ),
                            ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (hasDiscount) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isCompact ? 5 : 10,
                                        vertical: isCompact ? 2 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(
                                              isCompact ? 6 : 12),
                                          bottomLeft: Radius.circular(
                                              isCompact ? 6 : 12),
                                        ),
                                      ),
                                      child: Text(
                                        '৳${originalPrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: isCompact ? 9 : 14,
                                          color: Colors.grey.shade600,
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '৳${effectivePrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: isCompact ? 14 : 26,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF7A4F01),
                                      ),
                                    ),
                                    SizedBox(width: isCompact ? 3 : 8),
                                    Tooltip(
                                      message: 'Discounted price',
                                      child: Icon(
                                        Icons.local_offer_rounded,
                                        size: isCompact ? 12 : 18,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'You save ৳${course.savedAmount?.toStringAsFixed(0) ?? '0'}',
                                  style: TextStyle(
                                    fontSize: isCompact ? 9 : 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  '৳${originalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: isCompact ? 14 : 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF7A4F01),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    )
                  else if (!isFree &&
                      !isEnrolled &&
                      originalPrice == null)
                    Padding(
                      padding: EdgeInsets.only(top: isCompact ? 2 : 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (onEnroll != null)
                            Text(
                              'Details',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: isCompact ? 9 : 12,
                              ),
                            ),
                          Text(
                            'Paid',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              fontSize: isCompact ? 10 : null,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // DESCRIPTION (full width)
                  SizedBox(height: isCompact ? 4 : 8),
                  Text(
                    course.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: isCompact ? 10 : null,
                      height: isCompact ? 1.3 : null,
                    ),
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (isEnrolled) ...[
                    SizedBox(height: isCompact ? 6 : 14),

                    // PROGRESS
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: course.completionPercentage.clamp(
                                0.0,
                                1.0,
                              ),
                              minHeight: isCompact ? 6 : 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                course.completionPercentage >= 1.0
                                    ? Colors.green
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isCompact ? 6 : 10),
                        Text(
                          '${(course.completionPercentage * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: course.completionPercentage >= 1.0
                                ? Colors.green
                                : Colors.grey.shade700,
                            fontSize: isCompact ? 10 : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded badge used for FREE / PREMIUM / ENROLLED.
class _Pill extends StatelessWidget {
  final Gradient? gradient;
  final Color? color;
  final IconData icon;
  final String label;
  final bool gold;
  final bool isCompact;

  const _Pill({
    this.gradient,
    this.color,
    required this.icon,
    required this.label,
    this.gold = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 5 : 11,
        vertical: isCompact ? 2 : 5,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        color: color,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 20),
        border: gold
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.6), width: 1)
            : null,
        boxShadow: gold
            ? [
                BoxShadow(
                  color: const Color(0xFFB8860B).withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: gold ? const Color(0xFF7A4F01) : Colors.white,
            size: isCompact ? 10 : 14,
          ),
          SizedBox(width: isCompact ? 2 : 5),
          Text(
            label,
            style: TextStyle(
              color: gold ? const Color(0xFF7A4F01) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 9 : 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small neutral tag for Year / Subject metadata.
class _Tag extends StatelessWidget {
  final String text;
  final bool isCompact;

  const _Tag({
    required this.text,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 5 : 10,
        vertical: isCompact ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(isCompact ? 6 : 20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isCompact ? 9 : 12,
        ),
      ),
    );
  }
}

class CourseCardSkeleton extends StatelessWidget {
  final bool isCompact;

  const CourseCardSkeleton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: isCompact ? 2 : 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: Colors.grey.shade300),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 10 : 14,
              isCompact ? 8 : 12,
              isCompact ? 10 : 14,
              isCompact ? 10 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                  height: isCompact ? 14 : 20,
                  width: double.infinity,
                ),
                SizedBox(height: isCompact ? 4 : 10),
                _ShimmerBox(
                  height: isCompact ? 11 : 14,
                  width: isCompact ? 100 : 120,
                ),
                SizedBox(height: isCompact ? 4 : 10),
                _ShimmerBox(
                  height: isCompact ? 11 : 14,
                  width: isCompact ? 140 : 160,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.width, required this.height})
    : borderRadius = 4;

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.grey.shade300,
      ),
    );
  }
}
