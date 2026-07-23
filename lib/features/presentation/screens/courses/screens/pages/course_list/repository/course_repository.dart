import 'dart:async';

import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class CourseRepository {
  final SupabaseClient _supabase;

  CourseRepository(this._supabase);

  Future<List<Course>> getCourses({
    int limit = 10,
    int offset = 0,
    String? year,
    String? subject,
    String? type,
    bool includeChapters = true,
  }) async {
    try {
      var query = _supabase.from('course').select(
        includeChapters ? '*, chapter ( *, lesson (*))' : '*',
      );

      if (year != null && year != 'All') {
        query = query.eq('year', year);
      }

      if (subject != null && subject != 'All') {
        query = query.eq('subject', subject.toLowerCase());
      }

      if (type != null && type != 'All') {
        if (type == 'Free') {
          query = query.eq('is_free', true);
        } else if (type == 'Paid') {
          query = query.eq('is_free', false);
        }
      }

      var ordered = query
          .order('position', ascending: true)
          .order('created_at', ascending: true);

      if (includeChapters) {
        ordered = ordered
            .order('position', referencedTable: 'chapter', ascending: true)
            .order('created_at', referencedTable: 'chapter', ascending: true)
            .order(
              'position',
              referencedTable: 'chapter.lesson',
              ascending: true,
            )
            .order(
              'created_at',
              referencedTable: 'chapter.lesson',
              ascending: true,
            );
      }

      final response = await ordered.range(offset, offset + limit - 1).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Course list fetch timeout'),
      );

      /* print(const JsonEncoder.withIndent('  ').convert(response)); */
      return (response as List<dynamic>)
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      developer.log(e.toString(), error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Course?> getCourseById(int id) async {
    try {
      final courseJson = await _supabase
          .from('course')
          .select('*')
          .eq('id', id)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('Course detail fetch timeout'),
          );

      if (courseJson == null) return null;

      try {
        final chaptersJson = await _supabase
            .from('chapter')
            .select('*')
            .eq('course_id', id)
            .order('position', ascending: true)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('Chapter fetch timeout'),
            );

        final chapterIds = (chaptersJson as List)
            .map((c) => (c as Map<String, dynamic>)['id'])
            .where((e) => e != null)
            .toList();

        final lessonsByChapter = <String, List<Map<String, dynamic>>>{};
        if (chapterIds.isNotEmpty) {
          final lessonsJson = await _supabase
              .from('lesson')
              .select('*')
              .inFilter('chapter_id', chapterIds)
              .order('position', ascending: true)
              .timeout(
                const Duration(seconds: 8),
                onTimeout: () => throw TimeoutException('Lesson fetch timeout'),
              );

          for (final l in lessonsJson as List) {
            final map = l as Map<String, dynamic>;
            final cid = map['chapter_id']?.toString();
            if (cid != null) {
              lessonsByChapter.putIfAbsent(cid, () => []).add(map);
            }
          }
        }

        final chaptersWithLessons = (chaptersJson as List).map((c) {
          final map = Map<String, dynamic>.from(c as Map<String, dynamic>);
          map['lesson'] = lessonsByChapter[map['id'].toString()] ?? [];
          return map;
        }).toList();

        (courseJson)['chapter'] = chaptersWithLessons;
      } catch (e, st) {
        developer.log(
          'getCourseById: failed to load chapters for course $id: $e',
          error: e,
          stackTrace: st,
        );
      }

      return Course.fromJson(courseJson);
    } catch (e, stackTrace) {
      developer.log(e.toString(), error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Course>> getCoursesByIds(
    List<int> ids, {
    bool includeChapters = false,
  }) async {
    if (ids.isEmpty) return [];

    try {
      final response = await _supabase
          .from('course')
          .select(includeChapters ? '*, chapter ( *, lesson (*))' : '*')
          .inFilter('id', ids)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('Courses by IDs fetch timeout'),
          );

      return (response as List<dynamic>)
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      developer.log(e.toString(), error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
