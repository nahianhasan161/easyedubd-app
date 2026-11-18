import 'dart:io';

import 'package:test/test.dart';

/// Local test that validates the cache_version migration file.
///
/// This is NOT a database test — it never touches your live Supabase.
/// It only reads the SQL file and checks that it's well-formed and safe:
///   - All statements are idempotent (CREATE IF NOT EXISTS / OR REPLACE
///     / DROP IF EXISTS / INSERT ON CONFLICT).
///   - No DROP TABLE / DROP FUNCTION / DELETE / TRUNCATE statements.
///   - The file creates the cache_version table, the bump_cache_version
///     function, and one trigger per tracked table.
///   - The tracked table names match the ones the Flutter app uses.
void main() {
  group('cache_version migration', () {
    late String sql;

    setUpAll(() {
      final file = File(
        'supabase/migrations/0008_cache_version_mechanism.sql',
      );
      sql = file.readAsStringSync();
    });

    test('file exists and is non-empty', () {
      expect(sql.isNotEmpty, isTrue);
    });

    test('creates the cache_version table', () {
      expect(
        sql.contains('create table if not exists public.cache_version'),
        isTrue,
        reason: 'Migration must create the cache_version table',
      );
    });

    test('creates the bump_cache_version function', () {
      expect(
        sql.contains(
          'create or replace function public.bump_cache_version()',
        ),
        isTrue,
        reason: 'Migration must create or replace the bump function',
      );
    });

    test('triggers all 8 expected tables', () {
      // Map of table name -> trigger name (most are identical, but
      // some use a shortened form to keep the trigger name short).
      final expectedTriggers = {
        'course': 'trg_bump_course',
        'chapter': 'trg_bump_chapter',
        'lesson': 'trg_bump_lesson',
        'enrollments': 'trg_bump_enrollment',
        'bundle': 'trg_bump_bundle',
        'bundle_courses': 'trg_bump_bundle_courses',
        'promotion': 'trg_bump_promotion',
        'promotion_course': 'trg_bump_promotion_course',
      };
      // Strip line comments and normalize whitespace so multi-line
      // trigger definitions match correctly.
      final codeOnly = sql
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n');
      final normalized = codeOnly.replaceAll(RegExp(r'\s+'), ' ');
      for (final entry in expectedTriggers.entries) {
        final table = entry.key;
        final triggerName = entry.value;
        expect(
          normalized.contains(
            '$triggerName after insert or update or delete on public.$table',
          ),
          isTrue,
          reason: 'Missing trigger for table: $table (expected $triggerName)',
        );
      }
    });

    test('no DROP TABLE statements (data safety)', () {
      // Strip comments to avoid false positives from `-- DROP TABLE`
      // in the comment block.
      final codeOnly = sql
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n');
      expect(
        codeOnly.contains(RegExp(r'\bdrop\s+table\b', caseSensitive: false)),
        isFalse,
        reason: 'Migration must not drop any existing tables',
      );
    });

    test('no TRUNCATE statements (data safety)', () {
      final codeOnly = sql
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n');
      expect(
        codeOnly.toLowerCase().contains('truncate'),
        isFalse,
        reason: 'Migration must not truncate any tables',
      );
    });

    test('no DELETE FROM statements (data safety)', () {
      final codeOnly = sql
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n');
      expect(
        codeOnly.toLowerCase().contains(RegExp(r'\bdelete\s+from\b')),
        isFalse,
        reason: 'Migration must not delete from any tables',
      );
    });

    test('no DROP FUNCTION statements (data safety)', () {
      final codeOnly = sql
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n');
      expect(
        codeOnly.toLowerCase().contains(RegExp(r'\bdrop\s+function\b')),
        isFalse,
        reason:
            'Migration uses CREATE OR REPLACE FUNCTION, not DROP FUNCTION',
      );
    });

    test('enables RLS on cache_version', () {
      expect(
        sql.contains(
          'alter table public.cache_version enable row level security',
        ),
        isTrue,
        reason: 'Migration must enable RLS on the new table',
      );
    });

    test('creates a read policy for the cache_version row', () {
      expect(
        sql.contains('cache_version_read'),
        isTrue,
        reason: 'Migration must create a SELECT policy for the client',
      );
    });

    test('every CREATE TRIGGER is preceded by DROP TRIGGER IF EXISTS '
        '(idempotency)', () {
      // Normalize whitespace and strip line comments so multi-line
      // trigger definitions match and comment text doesn't pollute the
      // result.
      final codeOnly = sql
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n');
      final normalized = codeOnly.replaceAll(RegExp(r'\s+'), ' ');
      // Extract every "create trigger" name and verify a matching
      // "drop trigger if exists" exists in the same file.
      final triggerNames = <String>[];
      for (final match in RegExp(
        r'create\s+trigger\s+(\w+)',
        caseSensitive: false,
      ).allMatches(normalized)) {
        triggerNames.add(match.group(1)!);
      }
      expect(triggerNames, isNotEmpty);
      for (final name in triggerNames) {
        expect(
          normalized.contains('drop trigger if exists $name on'),
          isTrue,
          reason: 'Trigger $name must be preceded by a DROP IF EXISTS',
        );
      }
    });
  });
}
