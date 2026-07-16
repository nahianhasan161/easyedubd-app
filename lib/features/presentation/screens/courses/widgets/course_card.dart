import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/shared/widgets/App_cached_image.dart';
import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final bool isEnrolled;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.isEnrolled = false,
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

                // ENROLLED BADGE (top-left)
                if (isEnrolled)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _Pill(
                      color: Colors.blue,
                      icon: Icons.check_circle,
                      label: 'ENROLLED',
                    ),
                  ),

                // FREE / PREMIUM BADGE (top-right)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _Pill(
                    gradient: isFree
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFFFF1B8), Color(0xFFE6A817)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isFree ? Colors.green : null,
                    icon: isFree ? Icons.check_circle : Icons.workspace_premium_outlined,
                    label: isFree ? 'FREE' : 'PREMIUM',
                    gold: !isFree,
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
                    style: theme.textTheme.titleMedium?.copyWith(
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
                              isEnrolled ? theme.colorScheme.primary : const Color(0xFFB8860B),
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
