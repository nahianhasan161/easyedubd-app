import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/widgets/course_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A polished, card-style horizontal slider for a list of courses.
///
/// Each section on the Dashboard is rendered as a self-contained card so the
/// three sliders feel like distinct units rather than a single wall of cards.
/// The card has:
///   - An accent icon next to the title for quick visual identification.
///   - An optional subtitle shown under the title (e.g. "(2nd year)" or the
///     total count of items in the section).
///   - A thin accent line under the header to anchor the section.
///   - A rounded background and subtle shadow that lift it off the page.
///   - A right-edge gradient + pulsing arrow that fades in when the user
///     hasn't scrolled to the end, telling them there are more items.
class CourseSlider extends StatefulWidget {
  /// Section title shown in the header.
  final String title;

  /// Optional secondary line under the title (e.g. year filter or count).
  final String? subtitle;

  /// Courses to display in the horizontal scroll.
  final List<Course> courses;

  /// Accent icon shown to the left of the title.
  final IconData icon;

  /// Color of the accent icon and the thin underline below the header.
  /// Defaults to the theme's primary color.
  final Color? accentColor;

  /// Called when the user taps a course card.
  final void Function(Course course)? onTapCourse;

  /// Called when the user taps "View All" (top-right). If null, the
  /// button is hidden.
  final VoidCallback? onViewAll;

  /// Message shown in the empty state when [courses] is empty.
  final String? emptyMessage;

  /// Whether the list is still loading (shows skeleton cards).
  final bool isLoading;

  const CourseSlider({
    super.key,
    required this.title,
    required this.courses,
    this.subtitle,
    this.icon = Icons.menu_book_rounded,
    this.accentColor,
    this.onTapCourse,
    this.onViewAll,
    this.emptyMessage,
    this.isLoading = false,
  });

  @override
  State<CourseSlider> createState() => _CourseSliderState();
}

class _CourseSliderState extends State<CourseSlider> {
  final ScrollController _scrollController = ScrollController();
  // When the user has scrolled, we stop showing the "scroll right" hint
  // even if they scroll back to the start. This is intentional — the
  // hint is a "you haven't explored this section yet" cue, not a
  // navigation aid.
  bool _userHasScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > 8 && !_userHasScrolled) {
      setState(() => _userHasScrolled = true);
    }
  }

  bool get _shouldShowHint {
    if (_userHasScrolled) return false;
    if (widget.courses.length <= 1) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER: icon + title/subtitle (left), View All (right).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.onViewAll != null)
                  TextButton(
                    onPressed: widget.onViewAll,
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Thin accent underline.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // HORIZONTAL SCROLL + right-edge scroll hint overlay.
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 14),
            child: SizedBox(
              height: 230,
              child: Stack(
                children: [
                  Positioned.fill(child: _buildContent(context)),
                  if (_shouldShowHint)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: 56,
                      child: IgnorePointer(
                        child: _ScrollRightHint(accent: accent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.isLoading) {
      return ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const SizedBox(
          width: 170,
          child: CourseCardSkeleton(isCompact: true),
        ),
      );
    }

    if (widget.courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyState(
          icon: widget.icon,
          message: widget.emptyMessage ?? 'Nothing to show yet.',
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.courses.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final course = widget.courses[index];
        return SizedBox(
          width: 200,
          child: CourseCard(
            course: course,
            isCompact: true,
            isEnrolled: course.is_free,
            onTap: () {
              if (widget.onTapCourse != null) {
                widget.onTapCourse!(course);
              } else {
                context.push('/course/${course.id}');
              }
            },
            onEnroll: () => context.push('/course/${course.id}'),
          ),
        );
      },
    );
  }
}

/// Right-edge gradient + pulsing chevron that fades in when the user
/// hasn't scrolled the slider yet. Communicates "there are more items to
/// the right" without any text.
class _ScrollRightHint extends StatefulWidget {
  final Color accent;
  const _ScrollRightHint({required this.accent});

  @override
  State<_ScrollRightHint> createState() => _ScrollRightHintState();
}

class _ScrollRightHintState extends State<_ScrollRightHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Edge fade gradient.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.colorScheme.surface.withValues(alpha: 0.0),
                theme.colorScheme.surface.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        // Pulsing chevron in the middle of the strip.
        Center(
          child: FadeTransition(
            opacity: _pulse,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0.25, 0),
              ).animate(_pulse),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
