import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/dashboard/providers/dashboard_courses_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:easyedubd_app/shared/widgets/course_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "Dashboard" tab — a quick overview with three horizontal sliders:
/// 1. My Courses — the user's enrolled courses.
/// 2. Recommended for you — courses matching the user's currentYear,
///    excluding ones they're already enrolled in.
/// 3. All Courses — a preview of the catalog with a "View All" link.
///
/// All data is read from existing providers (which are cache-first), so
/// this screen is free to render instantly and costs no extra network on
/// a warm cache.
class DashboardTabScreen extends ConsumerStatefulWidget {
  /// Called when the user taps "View All" on the My Courses or All
  /// Courses slider. The parent DashboardScreen uses this to switch
  /// the bottom-nav tab.
  final void Function(int tabIndex) onSwitchTab;

  const DashboardTabScreen({super.key, required this.onSwitchTab});

  @override
  ConsumerState<DashboardTabScreen> createState() =>
      _DashboardTabScreenState();
}

class _DashboardTabScreenState extends ConsumerState<DashboardTabScreen> {
  /// Take the first N courses from a slider. Keeps the slider snappy and
  /// avoids fetching more than the viewport can show.
  static const int _sliderLimit = 10;

  @override
  Widget build(BuildContext context) {
    // Watch just the bits we need so unrelated state changes don't
    // rebuild the whole dashboard.
    //
    // IMPORTANT: the dashboard's "All Courses" and "Recommended" sliders
    // read from `allCoursesForDashboardProvider` — NOT from
    // `courseListProvider(false)`. The latter holds the currently-filtered
    // results of the All Courses tab, so reading from it would make the
    // dashboard reflect whatever filter the user last applied there.
    final allCoursesAsync = ref.watch(allCoursesForDashboardProvider);
    final myState = ref.watch(courseListProvider(true));
    final enrolledIdsAsync = ref.watch(enrolledCourseIdsProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final isOffline = ref.watch(isOfflineProvider);

    final enrolledIds = enrolledIdsAsync.value ?? <int>{};
    final myCourses = myState.courses;
    final allCourses = allCoursesAsync.value ?? const <Course>[];
    final isAllCoursesLoading = allCoursesAsync.isLoading && allCourses.isEmpty;

    // Recommended: match the user's currentYear + department (subject),
    // excluding enrolled courses. Falls back to year-only, then to
    // "everything not enrolled" if either field is missing.
    final currentYear = profileAsync.value?.currentYear;
    final department = profileAsync.value?.department;
    final recommended = _filterRecommended(
      allCourses: allCourses,
      currentYear: currentYear,
      department: department,
      enrolledIds: enrolledIds,
    );

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (isOffline) _OfflineBanner(),
          // 1. Recommended for you (most relevant, year+department aware).
          CourseSlider(
            icon: Icons.auto_awesome_rounded,
            accentColor: Colors.deepPurple,
            title: 'Recommended for you',
            subtitle: _recommendedSubtitle(currentYear, department),
            courses: recommended.take(_sliderLimit).toList(),
            isLoading: isAllCoursesLoading,
            emptyMessage:
                'No recommendations yet. Browse the catalog to discover courses.',
          ),
          const SizedBox(height: 16),
          // 2. All Courses, with the user's department sorted to the top.
          CourseSlider(
            icon: Icons.menu_book_rounded,
            title: 'All Courses',
            subtitle: department != null && department.isNotEmpty
                ? '$department courses first'
                : 'Browse the full catalog',
            courses: _allCoursesForDisplay(allCourses, department)
                .take(_sliderLimit)
                .toList(),
            isLoading: isAllCoursesLoading,
            onViewAll: () => widget.onSwitchTab(1),
            emptyMessage: 'No courses available yet.',
          ),
          const SizedBox(height: 16),
          // 3. My Courses (enrolled).
          CourseSlider(
            icon: Icons.school_rounded,
            accentColor: Colors.teal,
            title: 'My Courses',
            subtitle: myCourses.isEmpty
                ? 'Pick up where you left off'
                : '${myCourses.length} enrolled',
            courses: myCourses.take(_sliderLimit).toList(),
            isLoading: myState.isInitialLoading && myCourses.isEmpty,
            onViewAll: () => widget.onSwitchTab(2),
            emptyMessage:
                'You aren\'t enrolled in any courses yet. Browse the catalog to get started.',
          ),
        ],
      ),
    );
  }

  /// Returns the catalog sorted so the user's department appears first,
  /// then everything else in catalog order. Used for the "All Courses"
  /// slider on the dashboard.
  List<Course> _allCoursesForDisplay(
    List<Course> allCourses,
    String? department,
  ) {
    final aliases = _subjectAliasesFor(department?.trim().toLowerCase());
    if (aliases == null) return allCourses;
    return [
      ...allCourses.where((c) => aliases.contains(c.subject.toLowerCase())),
      ...allCourses.where((c) => !aliases.contains(c.subject.toLowerCase())),
    ];
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(enrolledCourseIdsProvider);
    // Await the enrollment future so the My Courses slider has the
    // freshest set before it refetches.
    try {
      await ref.read(enrolledCourseIdsProvider.future);
    } catch (_) {
      // The provider never errors by design, but be safe.
    }
    // The dashboard's "All Courses" and "Recommended" sliders read from
    // `allCoursesForDashboardProvider` — refresh that independently of
    // the filter-aware `courseListProvider(false)` so the dashboard
    // doesn't get contaminated by any filter state on the All Courses
    // tab.
    await ref
        .read(allCoursesForDashboardProvider.notifier)
        .refresh();
    await ref
        .read(courseListProvider(true).notifier)
        .loadInitial(forceRefresh: true);
  }

  /// Builds a prioritized recommendation list for the student.
  ///
  /// Buckets, in priority order:
  ///   1. Current year + student's department (major courses, this term)
  ///   2. Current year + non-major (other subjects at this level)
  ///   3. Older years + matching department (failed major courses from
  ///      previous years)
  ///   4. Older years + non-major (failed non-major courses)
  ///   5. Next year + matching department (profile year might be stale)
  ///   6. Next year + non-major
  ///   7. Anything else not yet enrolled (catch-all)
  ///
  /// Within a bucket, the original catalog order is preserved. A course
  /// appears in the highest-priority bucket it qualifies for, never
  /// duplicated.
  List<Course> _filterRecommended({
    required List<Course> allCourses,
    required String? currentYear,
    required String? department,
    required Set<int> enrolledIds,
  }) {
    final yearNum = _extractYearNumber(currentYear);
    final subjectAliases = _subjectAliasesFor(department?.trim().toLowerCase());

    // No profile year → fall back to the simpler "unassigned + everything
    // not enrolled" merge so the slider isn't empty.
    if (yearNum == null) {
      return allCourses.where((c) => !enrolledIds.contains(c.id)).toList();
    }

    final notEnrolled =
        allCourses.where((c) => !enrolledIds.contains(c.id)).toList();

    bool isMajor(Course c) {
      if (subjectAliases == null) return false;
      return subjectAliases.contains(c.subject.toLowerCase());
    }

    bool isOlder(Course c) {
      final n = _extractYearNumber(c.year);
      return n != null && n < yearNum;
    }

    bool isNext(Course c) {
      final n = _extractYearNumber(c.year);
      return n != null && n == yearNum + 1;
    }

    bool isCurrent(Course c) => _yearMatches(c.year, yearNum);

    final result = <Course>[];
    final seen = <int>{};

    void addBucket(bool Function(Course) test) {
      for (final c in notEnrolled) {
        // Check first, then add — so courses that don't match the
        // current bucket are still eligible for later buckets.
        if (!seen.contains(c.id) && test(c)) {
          seen.add(c.id);
          result.add(c);
        }
      }
    }

    // 1. Current year + major
    addBucket((c) => isCurrent(c) && isMajor(c));
    // 2. Current year + non-major
    addBucket((c) => isCurrent(c) && !isMajor(c));
    // 3. Older years + major
    addBucket((c) => isOlder(c) && isMajor(c));
    // 4. Older years + non-major
    addBucket((c) => isOlder(c) && !isMajor(c));
    // 5. Next year + major
    addBucket((c) => isNext(c) && isMajor(c));
    // 6. Next year + non-major
    addBucket((c) => isNext(c) && !isMajor(c));
    // 7. Anything else not enrolled (catch-all)
    addBucket((_) => true);

    return result;
  }

  /// Maps a profile department (e.g. "Mathematics") to the set of
  /// course subject values that should count as a match
  /// (e.g. {"math", "mathematics"}). Returns null if the department
  /// isn't recognised, so the caller can skip subject filtering.
  Set<String>? _subjectAliasesFor(String? department) {
    if (department == null || department.isEmpty) return null;
    switch (department) {
      case 'chemistry':
        return {'chemistry'};
      case 'mathematics':
        return {'math', 'mathematics'};
      case 'physics':
        return {'physics'};
      case 'zoology':
        return {'zoology'};
      case 'botany':
        return {'botany'};
      default:
        // "Other" or any custom value — fall back to exact match.
        return {department};
    }
  }

  /// Extracts the leading integer from a year string like "2", "2nd",
  /// "2nd Year", "Year 2". Returns null if no digit is found.
  int? _extractYearNumber(String? year) {
    if (year == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(year.trim());
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// True if [courseYear] (e.g. "2nd", "2", "2nd Year") refers to [yearNum].
  bool _yearMatches(String courseYear, int yearNum) {
    final courseYearNum = _extractYearNumber(courseYear);
    return courseYearNum != null && courseYearNum == yearNum;
  }

  /// Builds the subtitle for the "Recommended for you" section. Shows
  /// the student's year and department (e.g. "2nd year • Mathematics") so
  /// the user understands what the recommendations are based on.
  String _recommendedSubtitle(String? currentYear, String? department) {
    final yearNum = _extractYearNumber(currentYear);
    final yearLabel = yearNum != null ? _ordinalYear(yearNum) : null;
    final dept = department?.trim();
    final parts = <String>[];
    if (yearLabel != null) parts.add(yearLabel);
    if (dept != null && dept.isNotEmpty) parts.add(dept);
    if (parts.isEmpty) return 'Tailored to your profile';
    return parts.join(' • ');
  }

  /// "1" → "1st year", "2" → "2nd year", etc.
  String _ordinalYear(int n) {
    final suffix = switch (n % 100) {
      >= 11 && <= 13 => 'th',
      _ => switch (n % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        },
    };
    return '$n$suffix year';
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.amber.shade700,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: const [
              Icon(Icons.wifi_off, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You\'re offline. Showing cached courses.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
