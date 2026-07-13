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
  bool _filtersExpanded = false;

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

  Widget _buildChipRow({
    required String label,
    required List<String> options,
    required String selected,
    required void Function(String) onSelected,
    bool showCheckmark = false,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
                color: primary.withValues(alpha: 0.75),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: options.map((option) {
                final isActive = selected == option;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(option),
                    selected: isActive,
                    showCheckmark: showCheckmark && option != 'All',
                    onSelected: (_) => onSelected(option),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: isActive ? 2 : 0,
                    pressElevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    selectedColor: primary,
                    checkmarkColor: theme.colorScheme.onPrimary,
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(
                      color: isActive ? primary : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? theme.colorScheme.onPrimary
                          : Colors.grey.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChipRow(
            label: 'Year',
            options: const ['All', '1st', '2nd', '3rd', '4th'],
            selected: selectedYear,
            onSelected: (value) {
              setState(() => selectedYear = value);
              ref
                  .read(courseListProvider(widget.enrolledOnly).notifier)
                  .updateFilters(year: value);
            },
          ),
          const Divider(height: 4, thickness: 1),
          _buildChipRow(
            label: 'Subject',
            options: const ['All', 'Math', 'Physics', 'Chemistry', 'Biology'],
            selected: selectedSubject,
            onSelected: (value) {
              setState(() => selectedSubject = value);
              ref
                  .read(courseListProvider(widget.enrolledOnly).notifier)
                  .updateFilters(subject: value);
            },
          ),
          const Divider(height: 4, thickness: 1),
          _buildChipRow(
            label: 'Type',
            options: const ['All', 'Free', 'Paid'],
            selected: selectedType,
            showCheckmark: true,
            onSelected: (value) {
              setState(() => selectedType = value);
              ref
                  .read(courseListProvider(widget.enrolledOnly).notifier)
                  .updateFilters(type: value);
            },
          ),
        ],
      ),
    );
  }

  Widget _activeChip(String label, String value, VoidCallback onRemove) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(color: primary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildFilterHeader() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final chips = <Widget>[];
    if (selectedYear != 'All') {
      chips.add(_activeChip('Year', selectedYear, () => _clearFilter('year')));
    }
    if (selectedSubject != 'All') {
      chips.add(
        _activeChip('Subject', selectedSubject, () => _clearFilter('subject')),
      );
    }
    if (selectedType != 'All') {
      chips.add(_activeChip('Type', selectedType, () => _clearFilter('type')));
    }

    return GestureDetector(
      onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
      child: Container(
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
            Row(
              children: [
                Icon(Icons.filter_list, size: 20, color: primary),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: chips),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _clearFilter(String dimension) {
    setState(() {
      if (dimension == 'year') {
        selectedYear = 'All';
      } else if (dimension == 'subject') {
        selectedSubject = 'All';
      } else if (dimension == 'type') {
        selectedType = 'All';
      }
    });

    ref
        .read(courseListProvider(widget.enrolledOnly).notifier)
        .updateFilters(
          year: dimension == 'year' ? 'All' : null,
          subject: dimension == 'subject' ? 'All' : null,
          type: dimension == 'type' ? 'All' : null,
        );
  }

  Future<void> _refreshCourses() async {
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
              );
            },
          );

    final body = courseList.isInitialLoading
        ? const Center(child: CircularProgressIndicator())
        : courseList.error != null
        ? Center(
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
                      .read(courseListProvider(widget.enrolledOnly).notifier)
                      .loadInitial(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          )
        : RefreshIndicator(onRefresh: _refreshCourses, child: listChild);

    final content = GestureDetector(
      onTap: () {
        if (_filtersExpanded) setState(() => _filtersExpanded = false);
      },
      child: Column(
        children: [
          if (!widget.enrolledOnly) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Column(
                children: [
                  _buildFilterHeader(),
                  if (_filtersExpanded) _buildFilters(),
                ],
              ),
            ),
          ],
          Expanded(child: body),
        ],
      ),
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
