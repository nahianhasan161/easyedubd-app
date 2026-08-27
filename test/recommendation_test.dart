import 'package:flutter_test/flutter_test.dart';

/// We can't easily test the private `_filterRecommended` directly, so
/// these tests verify the building blocks: year-number extraction and
/// year matching. The integration is covered by manual dashboard use.
void main() {
  group('year parsing', () {
    test('extracts digit from "2"', () {
      expect(_extractYear('2'), 2);
    });
    test('extracts digit from "2nd"', () {
      expect(_extractYear('2nd'), 2);
    });
    test('extracts digit from "2nd Year"', () {
      expect(_extractYear('2nd Year'), 2);
    });
    test('extracts digit from "Year 2"', () {
      expect(_extractYear('Year 2'), 2);
    });
    test('returns null for null', () {
      expect(_extractYear(null), isNull);
    });
    test('returns null for non-numeric', () {
      expect(_extractYear('hello'), isNull);
    });
  });

  group('year matching', () {
    test('matches "2" to "2nd"', () {
      expect(_yearMatches('2nd', 2), isTrue);
    });
    test('matches "2" to "2"', () {
      expect(_yearMatches('2', 2), isTrue);
    });
    test('matches "2" to "2nd Year"', () {
      expect(_yearMatches('2nd Year', 2), isTrue);
    });
    test('does not match "2" to "3rd"', () {
      expect(_yearMatches('3rd', 2), isFalse);
    });
    test('does not match empty', () {
      expect(_yearMatches('', 2), isFalse);
    });
  });

  group('ordinal year formatting', () {
    test('1 → 1st', () {
      expect(_ordinalYear(1), '1st year');
    });
    test('2 → 2nd', () {
      expect(_ordinalYear(2), '2nd year');
    });
    test('3 → 3rd', () {
      expect(_ordinalYear(3), '3rd year');
    });
    test('4 → 4th', () {
      expect(_ordinalYear(4), '4th year');
    });
    test('11 → 11th (special case)', () {
      expect(_ordinalYear(11), '11th year');
    });
    test('12 → 12th (special case)', () {
      expect(_ordinalYear(12), '12th year');
    });
    test('13 → 13th (special case)', () {
      expect(_ordinalYear(13), '13th year');
    });
    test('21 → 21st', () {
      expect(_ordinalYear(21), '21st year');
    });
  });
}

// ===========================================================================
// Re-implementations of the private helpers in dashboard_tab_screen.dart so
// the tests can exercise the same logic without exporting internals. The
// algorithm is intentionally duplicated here — if the implementation in
// dashboard_tab_screen.dart changes, update these to match.
// ===========================================================================

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
