import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/shared/widgets/App_cached_image.dart';
import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final bool isEnrolled;
  final VoidCallback? onEnroll;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.isEnrolled = false,
    this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFree = course.is_free;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  height: 64,
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

                // BADGE (top-right)
                Positioned(
                  top: 10,
                  right: 10,
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
                    label: isEnrolled ? 'ENROLLED' : isFree ? 'FREE' : 'PREMIUM',
                    gold: !isEnrolled && !isFree,
                  ),
                ),

                // DISCOUNT BADGE (bottom-right of image)
                if (!isFree && !isEnrolled && course.price != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
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
                      child: const Text(
                        '-20%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // BODY
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    course.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // YEAR + SUBJECT
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (course.year.trim().isNotEmpty)
                        _Tag(text: '${course.year} Year'),
                      if (course.subject.trim().isNotEmpty)
                        _Tag(text: course.subject),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // DESCRIPTION
                   Text(
                     course.description,
                     style: theme.textTheme.bodyMedium?.copyWith(
                       color: Colors.grey.shade600,
                     ),
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                   ),

                  if (!isFree && !isEnrolled && course.price != null) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '৳${(course.price!).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1B8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '৳${(course.price! * 0.8).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7A4F01),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isEnrolled && onEnroll != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onEnroll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE6A817),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else if (!isFree && !isEnrolled && course.price == null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Paid',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (!isEnrolled && onEnroll != null) ...[
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: onEnroll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE6A817),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                    ),
                  ),

                  if (isEnrolled) ...[
                    const SizedBox(height: 14),

                    // PROGRESS
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: course.progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(course.progress * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
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

  const _Pill({
    this.gradient,
    this.color,
    required this.icon,
    required this.label,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient,
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: gold
            ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1)
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
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: gold ? const Color(0xFF7A4F01) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.4,
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

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
