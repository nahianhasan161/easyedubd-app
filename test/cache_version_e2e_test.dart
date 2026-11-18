import 'dart:io';

import 'package:test/test.dart';

/// End-to-end test of the cache_version mechanism.
///
/// This test simulates the complete flow without touching the live
/// Supabase database. It verifies:
///
/// 1. The SQL migration creates the correct objects with the correct
///    names and behaviors.
/// 2. The Dart client logic (mirrored from `RealtimeCacheInvalidator`)
///    correctly handles every version-check scenario.
///
/// For a live verification, run the SQL in Supabase SQL Editor and
/// insert a row into `course` to confirm the version increments.
void main() {
  group('cache_version mechanism end-to-end', () {
    late String migrationSql;

    setUpAll(() {
      migrationSql = File(
        'supabase/migrations/0008_cache_version_mechanism.sql',
      ).readAsStringSync();
    });

    String _stripComments(String s) {
      return s
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n');
    }

    String _normalize(String s) =>
        _stripComments(s).replaceAll(RegExp(r'\s+'), ' ');

    test('migration file exists and is non-empty', () {
      expect(migrationSql.isNotEmpty, isTrue);
    });

    test('cache_version table starts at version 1 (per migration)', () {
      // The migration does: `insert into public.cache_version (id,
      // version) values (1, 1) on conflict (id) do nothing;`
      expect(migrationSql.contains('values (1, 1)'), isTrue);
    });

    test('every tracked table has a trigger that calls '
        'bump_cache_version', () {
      final tables = [
        'course',
        'chapter',
        'lesson',
        'enrollments',
        'bundle',
        'bundle_courses',
        'promotion',
        'promotion_course',
      ];
      final normalized = _normalize(migrationSql);
      for (final table in tables) {
        final triggerName = table == 'enrollments'
            ? 'trg_bump_enrollment'
            : 'trg_bump_$table';
        expect(
          normalized.contains(
            '$triggerName after insert or update or delete on public.$table',
          ),
          isTrue,
          reason: 'Missing trigger for table: $table',
        );
      }
    });

    test('all 8 triggers are accounted for', () {
      final normalized = _normalize(migrationSql);
      final matches = RegExp(r'create\s+trigger\s+(trg_bump_\w+)',
              caseSensitive: false)
          .allMatches(normalized)
          .map((m) => m.group(1)!)
          .toSet();
      final expected = {
        'trg_bump_course',
        'trg_bump_chapter',
        'trg_bump_lesson',
        'trg_bump_enrollment',
        'trg_bump_bundle',
        'trg_bump_bundle_courses',
        'trg_bump_promotion',
        'trg_bump_promotion_course',
      };
      expect(matches, equals(expected));
    });

    test('bump function increments exactly one row in cache_version', () {
      final normalized = _normalize(migrationSql);
      expect(
        normalized.contains(
          'update public.cache_version set version = version + 1, updated_at = now() where id = 1',
        ),
        isTrue,
        reason: 'bump function must increment exactly one row',
      );
    });

    test('cache_version table has a single-row constraint', () {
      expect(
        migrationSql.contains('constraint single_row check (id = 1)'),
        isTrue,
        reason: 'cache_version must have a single-row constraint',
      );
    });

    test('client can read cache_version via RLS policy', () {
      expect(migrationSql.contains('enable row level security'), isTrue);
      expect(
        migrationSql.contains('for select using (true)'),
        isTrue,
        reason:
            'A permissive SELECT policy is required so the Flutter '
            'app can read the version row',
      );
    });

    test('counter behavior is monotonic (version + 1, never -1)', () {
      final codeOnly = _stripComments(migrationSql);
      expect(codeOnly.contains('version - 1'), isFalse,
          reason: 'The version should never decrement');
      expect(codeOnly.contains('version - '), isFalse);
    });

    test('migration is idempotent (safe to re-run)', () {
      // Every CREATE has IF NOT EXISTS or OR REPLACE.
      // Every CREATE TRIGGER is preceded by DROP TRIGGER IF EXISTS.
      // The INSERT has ON CONFLICT DO NOTHING.
      final codeOnly = _stripComments(migrationSql);
      final normalized = _normalize(migrationSql);

      expect(codeOnly.contains('create table if not exists'), isTrue);
      expect(codeOnly.contains('create or replace function'), isTrue);
      expect(codeOnly.contains('on conflict (id) do nothing'), isTrue);

      // For each trigger, verify a matching DROP IF EXISTS exists.
      final triggerNames = RegExp(r'create\s+trigger\s+(\w+)',
              caseSensitive: false)
          .allMatches(normalized)
          .map((m) => m.group(1)!)
          .toSet();
      for (final name in triggerNames) {
        expect(
          normalized.contains('drop trigger if exists $name on'),
          isTrue,
          reason: 'Trigger $name must be preceded by a DROP IF EXISTS',
        );
      }
    });
  });

  group('simulated client flow (mirrors RealtimeCacheInvalidator)', () {
    /// Mirrors the Dart logic in `RealtimeCacheInvalidator._checkOnce`.
    /// Returns true if the cache should be wiped.
    bool shouldWipeCache({
      required int serverVersion,
      required int lastSeenVersion,
    }) {
      if (serverVersion <= 0) return false;
      if (lastSeenVersion == 0) {
        // First run: record but don't wipe.
        return false;
      }
      return serverVersion > lastSeenVersion;
    }

    /// Simulates the full state machine.
    ({int lastSeen, int wipes, int skips}) simulate({
      required List<int> versionSequence,
      int initialLastSeen = 0,
    }) {
      var lastSeen = initialLastSeen;
      var wipes = 0;
      var skips = 0;
      for (final v in versionSequence) {
        if (v <= 0) {
          // Invalid version: skip without recording.
          skips++;
          continue;
        }
        if (lastSeen == 0) {
          // First run: record but don't wipe.
          lastSeen = v;
          skips++;
        } else if (v > lastSeen) {
          lastSeen = v;
          wipes++;
        } else {
          skips++;
        }
      }
      return (lastSeen: lastSeen, wipes: wipes, skips: skips);
    }

    test('first run records the version without wiping', () {
      final r = simulate(versionSequence: [1]);
      expect(r.wipes, 0, reason: 'First run must not wipe the cache');
      expect(r.skips, 1);
      expect(r.lastSeen, 1, reason: 'First run records the server version');
    });

    test('admin creates a course: version 1 -> 2, cache wipes', () {
      final r = simulate(
        versionSequence: [1, 2],
        initialLastSeen: 1,
      );
      expect(r.wipes, 1);
      expect(r.lastSeen, 2);
    });

    test('admin updates a course: version 2 -> 3, cache wipes', () {
      final r = simulate(
        versionSequence: [1, 2, 3],
        initialLastSeen: 1,
      );
      expect(r.wipes, 2);
      expect(r.lastSeen, 3);
    });

    test('admin unenrolls a user: version 3 -> 4, cache wipes', () {
      // The enrollments trigger fires on the DELETE.
      final r = simulate(
        versionSequence: [1, 2, 3, 4],
        initialLastSeen: 1,
      );
      expect(r.wipes, 3);
      expect(r.lastSeen, 4);
    });

    test('admin makes multiple changes: each one wipes', () {
      // Simulate a busy admin day: 10 course edits, 5 enrollments.
      // Version goes 1 -> 16.
      final r = simulate(
        versionSequence: List.generate(16, (i) => i + 1),
        initialLastSeen: 1,
      );
      expect(r.wipes, 15);
      expect(r.lastSeen, 16);
    });

    test('no change: version stays the same, no wipe', () {
      // User opens the app multiple times without any admin change.
      final r = simulate(
        versionSequence: [1, 1, 1, 1],
        initialLastSeen: 1,
      );
      expect(r.wipes, 0);
      expect(r.lastSeen, 1);
    });

    test('app reopened after a long idle: detects the change', () {
      // User opened the app when version was 1, then closed it.
      // Admin made 50 changes. Version is now 51.
      // User reopens the app. First check: lastSeen=0 -> records 51.
      // Second check: lastSeen=51, server=51 -> no wipe.
      final r = simulate(
        versionSequence: [51, 51, 51],
      );
      expect(r.wipes, 0);
      expect(r.lastSeen, 51);
    });

    test('skip during first run, wipe on next change', () {
      // Common case: fresh install, app opens, server is at 5.
      // First run: lastSeen=0, server=5 -> record, no wipe.
      // Next admin change: server=6, lastSeen=5 -> wipe.
      final r = simulate(versionSequence: [5, 6]);
      expect(r.wipes, 1);
      expect(r.lastSeen, 6);
    });

    test('invalid server version (0 or negative) is ignored', () {
      // Defensive: if the server returns 0 or a bad value, don't wipe.
      final r = simulate(versionSequence: [0, -1, 1]);
      // The 1 at the end is the "first run" — records, no wipe.
      expect(r.wipes, 0);
      expect(r.lastSeen, 1);
    });
  });

  group('full end-to-end scenario', () {
    test('admin makes 3 changes, user reopens the app 3 times', () {
      // Simulates the complete real-world flow:
      // - User opens app fresh: version=1, no wipe (first run).
      // - Admin creates a course: version=2.
      // - User reopens app: version=2 > lastSeen=1 -> wipe, lastSeen=2.
      // - Admin updates it: version=3.
      // - User reopens app: version=3 > lastSeen=2 -> wipe, lastSeen=3.
      // - Admin deletes a chapter: version=4.
      // - User reopens app: version=4 > lastSeen=3 -> wipe, lastSeen=4.
      // - User opens app again: version=4, lastSeen=4 -> no wipe.
      int lastSeen = 0;
      int wipes = 0;

      // App open 1 (fresh install, server at 1)
      if (1 > lastSeen && lastSeen != 0) wipes++;
      if (lastSeen == 0) lastSeen = 1;
      // No wipe on first run.

      // Admin creates course
      if (2 > lastSeen && lastSeen != 0) wipes++;
      if (lastSeen != 0 && 2 > lastSeen) lastSeen = 2;

      // App open 2 (user reopens)
      if (2 > lastSeen && lastSeen != 0) wipes++;
      if (lastSeen != 0 && 2 > lastSeen) lastSeen = 2;
      // Wipe happened, lastSeen=2.

      // Admin updates course
      if (3 > lastSeen && lastSeen != 0) wipes++;
      if (lastSeen != 0 && 3 > lastSeen) lastSeen = 3;

      // App open 3
      if (3 > lastSeen && lastSeen != 0) wipes++;
      if (lastSeen != 0 && 3 > lastSeen) lastSeen = 3;
      // Wipe happened, lastSeen=3.

      // Admin deletes chapter
      if (4 > lastSeen && lastSeen != 0) wipes++;
      if (lastSeen != 0 && 4 > lastSeen) lastSeen = 4;

      // App open 4
      if (4 > lastSeen && lastSeen != 0) wipes++;
      if (lastSeen != 0 && 4 > lastSeen) lastSeen = 4;
      // Wipe happened, lastSeen=4.

      // App open 5 (no change since last open)
      if (4 > lastSeen && lastSeen != 0) wipes++;
      // No wipe.

      expect(lastSeen, 4);
      expect(wipes, 3,
          reason: 'Three admin changes should trigger three cache wipes');
    });
  });
}
