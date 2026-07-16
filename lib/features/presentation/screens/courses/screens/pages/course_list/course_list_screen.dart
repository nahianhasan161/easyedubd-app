import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:easyedubd_app/features/presentation/screens/courses/widgets/course_card.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  final bool enrolledOnly;
  final bool showAppBar;

  const CourseListScreen({
    super.key,
    this.enrolledOnly = false,
    this.showAppBar = true,
  });

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  final ScrollController _scrollController = ScrollController();

  late String selectedYear;
  late String selectedSubject;
  late String selectedType;

  @override
  void initState() {
    super.initState();

    selectedYear = 'All';
    selectedSubject = 'All';
    selectedType = 'All';

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final notifier = ref.read(
        courseListProvider(widget.enrolledOnly).notifier,
      );

      ref
          .read(enrolledCourseIdsProvider)
          .whenData((ids) => notifier.setEnrolledCourseIds(ids));

      if (!widget.enrolledOnly) {
        notifier.loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(courseListProvider(widget.enrolledOnly).notifier).loadMore();
    }
  }

  Widget _buildFilterDropdown({
    required String label,
    required List<String> options,
    required String selected,
    required void Function(String) onSelected,
    String? allLabel,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isActive = selected != 'All';
    final defaultText = allLabel ?? 'All';

    // Display label for the "All" option so users know what the filter is.
    String display(String option) => option == 'All' ? defaultText : option;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isActive ? primary : Colors.grey.shade300),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isActive
                ? theme.colorScheme.onPrimary
                : Colors.grey.shade700,
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                display(option),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive && option == selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: isActive && option == selected ? primary : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            onSelected(value);
          },
          selectedItemBuilder: (context) {
            return options.map((option) {
              final active = option != 'All';
              return Text(
                display(option),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? theme.colorScheme.onPrimary
                      : Colors.grey.shade700,
                ),
              );
            }).toList();
          },
          style: TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
          dropdownColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildTopFilters() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 20, color: primary),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterDropdown(
                    label: 'Year',
                    allLabel: 'Year',
                    options: const ['All', '1st', '2nd', '3rd', '4th'],
                    selected: selectedYear,
                    onSelected: (value) {
                      setState(() => selectedYear = value);
                      ref
                          .read(courseListProvider(widget.enrolledOnly).notifier)
                          .updateFilters(year: value);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterDropdown(
                    label: 'Subject',
                    allLabel: 'Subject',
                    options: const [
                      'All',
                      'Math',
                      'Physics',
                      'Chemistry',
                      'Biology'
                    ],
                    selected: selectedSubject,
                    onSelected: (value) {
                      setState(() => selectedSubject = value);
                      ref
                          .read(courseListProvider(widget.enrolledOnly).notifier)
                          .updateFilters(subject: value);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterDropdown(
                    label: 'Type',
                    allLabel: 'Type',
                    options: const ['All', 'Free', 'Paid'],
                    selected: selectedType,
                    onSelected: (value) {
                      setState(() => selectedType = value);
                      ref
                          .read(courseListProvider(widget.enrolledOnly).notifier)
                          .updateFilters(type: value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshCourses() async {
    // For "My Courses", also re-fetch the enrollment set so a newly enrolled
    // course appears after pull-to-refresh (not just the cached ids).
    if (widget.enrolledOnly) {
      ref.invalidate(enrolledCourseIdsProvider);
    }
    await ref
        .read(courseListProvider(widget.enrolledOnly).notifier)
        .loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final courseList = ref.watch(courseListProvider(widget.enrolledOnly));

    ref.listen(enrolledCourseIdsProvider, (previous, next) {
      next.whenData(
        (ids) => ref
            .read(courseListProvider(widget.enrolledOnly).notifier)
            .setEnrolledCourseIds(ids),
      );
    });

    final listChild = courseList.courses.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              Center(child: Text('No courses found.')),
            ],
          )
        : ListView.builder(
            controller: _scrollController,
            // AlwaysScrollable lets pull-to-refresh work even when the list is
            // short (e.g. a single enrolled course) and can't otherwise overscroll.
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount:
                courseList.courses.length + (courseList.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == courseList.courses.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final course = courseList.courses[index];
              final isEnrolled =
                  widget.enrolledOnly ||
                  courseList.enrolledCourseIds?.contains(course.id) == true;

              return CourseCard(
                course: course,
                isEnrolled: isEnrolled || course.is_free,
                onTap: () {
                  context.push('/course/${course.id}');
                },
                onEnroll: () {
                  context.push('/course/${course.id}');
                },
              );
            },
          );

    final body = RefreshIndicator(
      onRefresh: _refreshCourses,
      child: courseList.isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : courseList.error != null
          // Scrollable so pull-to-refresh still works from the error state.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load courses.\nPlease check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(courseListProvider(widget.enrolledOnly)
                                .notifier)
                            .loadInitial(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : listChild,
    );

    final content = Column(
      children: [
        if (!widget.enrolledOnly) _buildTopFilters(),
        Expanded(child: body),
      ],
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.enrolledOnly ? 'My Courses' : 'All Courses'),
        centerTitle: false,
        elevation: 0,
      ),
      body: content,
    );
  }
}
