import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests exercise the priority-merge logic of
/// `_filterRecommended` in `dashboard_tab_screen.dart`. The algorithm
/// is re-implemented below as a pure function so it can be tested
/// without bringing up the full widget tree. If the implementation in
/// `dashboard_tab_screen.dart` changes, update `prioritizeCourses` to
/// match.

void main() {
  group('course prioritization', () {
    test(
      '3rd year Math student sees 3rd-year Math first, then 3rd-year '
      'non-major, then 1st/2nd year (failed), then 4th year, then catch-all',
      () {
        final catalog = [
          // Bucket 1: current year + major
          _c(101, year: '3rd', subject: 'Math'),
          _c(102, year: '3rd', subject: 'Mathematics'),
          // Bucket 2: current year + non-major
          _c(103, year: '3rd', subject: 'Physics'),
          _c(104, year: '3rd', subject: 'Chemistry'),
          // Bucket 3: older years + major (failed Math from years 1-2)
          _c(105, year: '2nd', subject: 'Math'),
          _c(106, year: '1st', subject: 'Math'),
          // Bucket 4: older years + non-major
          _c(107, year: '2nd', subject: 'Physics'),
          // Bucket 5: next year + major
          _c(108, year: '4th', subject: 'Math'),
          // Bucket 6: next year + non-major
          _c(109, year: '4th', subject: 'Chemistry'),
          // Catch-all
          _c(110, year: '5th', subject: 'Math'),
        ];

        final result = prioritizeCourses(
          allCourses: catalog,
          currentYear: '3',
          department: 'Mathematics',
          enrolledIds: const <int>{},
        );

        expect(
          result.map((c) => c.id),
          [101, 102, 103, 104, 105, 106, 107, 108, 109, 110],
          reason: 'Buckets should be merged in priority order, preserving '
              'catalog order within each bucket.',
        );
      },
    );

    test('a 2nd year Chemistry student gets Chemistry before other subjects '
        'in the same year', () {
      final catalog = [
        _c(1, year: '2nd', subject: 'Physics'),
        _c(2, year: '2nd', subject: 'Chemistry'),
        _c(3, year: '2nd', subject: 'Math'),
      ];

      final result = prioritizeCourses(
        allCourses: catalog,
        currentYear: '2',
        department: 'Chemistry',
        enrolledIds: const {},
      );

      // Chemistry comes first, then the others in catalog order.
      expect(result.map((c) => c.id), [2, 1, 3]);
    });

    test('enrolled courses are excluded from every bucket', () {
      final catalog = [
        _c(1, year: '2nd', subject: 'Math'),
        _c(2, year: '2nd', subject: 'Chemistry'),
        _c(3, year: '1st', subject: 'Math'),
      ];

      final result = prioritizeCourses(
        allCourses: catalog,
        currentYear: '2',
        department: 'Math',
        enrolledIds: {1}, // already enrolled in the major 2nd year course
      );

      expect(result.map((c) => c.id), [2, 3],
          reason: 'Course 1 is enrolled, so it should be filtered out.');
    });

    test('no profile year → falls back to "everything not enrolled"', () {
      final catalog = [
        _c(1, year: '2nd', subject: 'Math'),
        _c(2, year: '1st', subject: 'Chemistry'),
      ];

      final result = prioritizeCourses(
        allCourses: catalog,
        currentYear: null,
        department: 'Mathematics',
        enrolledIds: const {},
      );

      expect(result.map((c) => c.id), [1, 2]);
    });

    test('no department → current-year + non-major still wins, then '
        'catch-all', () {
      final catalog = [
        _c(1, year: '2nd', subject: 'Math'),
        _c(2, year: '2nd', subject: 'Physics'),
        _c(3, year: '1st', subject: 'Math'),
      ];

      final result = prioritizeCourses(
        allCourses: catalog,
        currentYear: '2',
        department: null,
        enrolledIds: const {},
      );

      // No department → isMajor() is always false, so the current-year
      // bucket only collects non-major. Older years and next year also
      // contribute non-major. Catch-all absorbs the rest.
      expect(result.map((c) => c.id), [1, 2, 3]);
    });

    test('profile year "2nd" matches course year "2nd Year"', () {
      final catalog = [
        _c(1, year: '2nd Year', subject: 'Math'),
        _c(2, year: '2nd', subject: 'Chemistry'),
      ];

      final result = prioritizeCourses(
        allCourses: catalog,
        currentYear: '2nd',
        department: 'Mathematics',
        enrolledIds: const {},
      );

      // Course 1: current year + major (Math).
      // Course 2: current year + non-major.
      expect(result.map((c) => c.id), [1, 2]);
    });

    test('a course never appears in more than one bucket', () {
      final catalog = [
        _c(1, year: '2nd', subject: 'Math'),
      ];

      final result = prioritizeCourses(
        allCourses: catalog,
        currentYear: '2',
        department: 'Math',
        enrolledIds: const {},
      );

      expect(result.length, 1);
      expect(result.first.id, 1);
    });

    test('older years come before next year in the output', () {
      final catalog = [
        _c(1, year: '1st', subject: 'Math'),
        _c(2, year: '4th', subject: 'Math'),
      ];

      final result = prioritizeCourses(
        allCourses: catalog,
        currentYear: '3',
        department: 'Math',
        enrolledIds: const {},
      );

      // Bucket 3 (older + major) → 1, then bucket 5 (next year + major) → 2.
      expect(result.map((c) => c.id), [1, 2]);
    });
  });

  group('allCoursesForDisplay (department-priority sort)', () {
    test("user's department courses come first, then everything else", () {
      final catalog = [
        _c(1, year: '1st', subject: 'Physics'),
        _c(2, year: '2nd', subject: 'Math'),
        _c(3, year: '3rd', subject: 'Chemistry'),
        _c(4, year: '1st', subject: 'Math'),
        _c(5, year: '2nd', subject: 'Zoology'),
      ];

      final result = allCoursesForDisplay(
        allCourses: catalog,
        department: 'Math',
      );

      // Math courses (2 and 4) come first in catalog order, then the rest.
      expect(result.map((c) => c.id), [2, 4, 1, 3, 5]);
    });

    test("'Mathematics' department also matches 'Math' subject (alias)", () {
      final catalog = [
        _c(1, year: '1st', subject: 'Math'),
        _c(2, year: '1st', subject: 'Mathematics'),
        _c(3, year: '1st', subject: 'Chemistry'),
      ];

      final result = allCoursesForDisplay(
        allCourses: catalog,
        department: 'Mathematics',
      );

      // Both 1 (subject=Math) and 2 (subject=Mathematics) match the
      // Mathematics department and appear first.
      expect(result.map((c) => c.id), [1, 2, 3]);
    });

    test('null department → original catalog order', () {
      final catalog = [
        _c(1, year: '1st', subject: 'Math'),
        _c(2, year: '1st', subject: 'Physics'),
      ];

      final result = allCoursesForDisplay(
        allCourses: catalog,
        department: null,
      );

      expect(result.map((c) => c.id), [1, 2]);
    });

    test('empty department string → original catalog order', () {
      final catalog = [
        _c(1, year: '1st', subject: 'Math'),
        _c(2, year: '1st', subject: 'Physics'),
      ];

      final result = allCoursesForDisplay(
        allCourses: catalog,
        department: '   ',
      );

      expect(result.map((c) => c.id), [1, 2]);
    });
  });
}

Course _c(int id, {required String year, required String subject}) => Course(
      id: id,
      title: 'C$id',
      description: '',
      imageUrl: '',
      progress: 0,
      is_free: false,
      status: 'published',
      year: year,
      subject: subject,
      chapters: const [],
    );

// ===========================================================================
// Mirror of `_filterRecommended` in dashboard_tab_screen.dart. If the
// implementation there changes, update this to match.
// ===========================================================================

List<Course> prioritizeCourses({
  required List<Course> allCourses,
  required String? currentYear,
  required String? department,
  required Set<int> enrolledIds,
}) {
  final yearNum = _extractYear(currentYear);
  final subjectAliases = _subjectAliasesFor(department?.trim().toLowerCase());

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
    final n = _extractYear(c.year);
    return n != null && n < yearNum;
  }

  bool isNext(Course c) {
    final n = _extractYear(c.year);
    return n != null && n == yearNum + 1;
  }

  bool isCurrent(Course c) => _yearMatches(c.year, yearNum);

  final result = <Course>[];
  final seen = <int>{};

  void addBucket(bool Function(Course) test) {
    for (final c in notEnrolled) {
      // Check first, then add — so courses that don't match the current
      // bucket are still eligible for later buckets.
      if (!seen.contains(c.id) && test(c)) {
        seen.add(c.id);
        result.add(c);
      }
    }
  }

  addBucket((c) => isCurrent(c) && isMajor(c));
  addBucket((c) => isCurrent(c) && !isMajor(c));
  addBucket((c) => isOlder(c) && isMajor(c));
  addBucket((c) => isOlder(c) && !isMajor(c));
  addBucket((c) => isNext(c) && isMajor(c));
  addBucket((c) => isNext(c) && !isMajor(c));
  addBucket((_) => true);

  return result;
}

int? _extractYear(String? year) {
  if (year == null) return null;
  final match = RegExp(r'(\d+)').firstMatch(year.trim());
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

bool _yearMatches(String courseYear, int yearNum) {
  final courseYearNum = _extractYear(courseYear);
  return courseYearNum != null && courseYearNum == yearNum;
}

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
      return {department};
  }
}

// Mirror of `_allCoursesForDisplay` in dashboard_tab_screen.dart.
List<Course> allCoursesForDisplay({
  required List<Course> allCourses,
  required String? department,
}) {
  final aliases = _subjectAliasesFor(department?.trim().toLowerCase());
  if (aliases == null) return allCourses;
  return [
    ...allCourses.where((c) => aliases.contains(c.subject.toLowerCase())),
    ...allCourses.where((c) => !aliases.contains(c.subject.toLowerCase())),
  ];
}
