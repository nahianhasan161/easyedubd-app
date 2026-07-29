import 'dart:async';
import 'dart:io';

import 'package:easyedubd_app/core/storage/local_cache_service.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/promotion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class CourseRepository {
  final SupabaseClient _supabase;
  final LocalCacheService _cache;

  CourseRepository(this._supabase, [LocalCacheService? cache])
      : _cache = cache ?? LocalCacheService();

  Future<List<Course>> getCourses({
    int limit = 10,
    int offset = 0,
    String? year,
    String? subject,
    String? type,
    bool includeChapters = true,
  }) async {
    final offline = !await _hasInternet();

    if (offline) {
      final cached = _cache.getCachedCourses();
      if (cached.isNotEmpty) {
        return cached.map((e) => Course.fromJson(e)).toList();
      }
      throw Exception('No internet connection and no cached courses available.');
    }

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

      final courses = (response as List<dynamic>)
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();

      if (courses.isNotEmpty) {
        final courseIds = courses.map((c) => c.id).toList();
        final promotions = await _getPromotionsForCourses(courseIds);
        for (final course in courses) {
          course.promotions = promotions[course.id] ?? const [];
        }
      }

      await _cache.cacheCourses(courses.map((c) => c.toJson()).toList());

      final cachedAfterWrite = _cache.getCachedCourses();
      if (cachedAfterWrite.isEmpty && courses.isNotEmpty) {
        developer.log('Warning: course cache write appeared to succeed but cached list is empty');
      }

      return courses;
    } catch (e, stackTrace) {
      developer.log(e.toString(), error: e, stackTrace: stackTrace);
      final cached = _cache.getCachedCourses();
      if (cached.isNotEmpty) {
        return cached.map((e) => Course.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  Future<Course?> getCourseById(int id) async {
    final offline = !await _hasInternet();

    if (offline) {
      // 1. Try individual course cache first.
      final cached = _cache.getCachedCourseById(id);
      if (cached != null) return Course.fromJson(cached);

      // 2. Fall back to general course list cache.
      final general = _cache.getCachedCourses();
      final found = general.firstWhere(
        (c) => (c['id'] as num?)?.toInt() == id,
        orElse: () => {},
      );
      if (found.isNotEmpty) return Course.fromJson(found);

      // 3. Fall back to enrolled course cache.
      final enrolled = _cache.getCachedEnrolledCourses();
      final foundEnrolled = enrolled.firstWhere(
        (c) => (c['id'] as num?)?.toInt() == id,
        orElse: () => {},
      );
      if (foundEnrolled.isNotEmpty) return Course.fromJson(foundEnrolled);

      return null;
    }

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

      final course = Course.fromJson(courseJson);
      await _cache.cacheCourseById(course.toJson());
      return course;
    } catch (e, stackTrace) {
      developer.log(e.toString(), error: e, stackTrace: stackTrace);
      final cached = _cache.getCachedCourseById(id);
      if (cached != null) return Course.fromJson(cached);
      return null;
    }
  }

  Future<List<Course>> getCoursesByIds(
    List<int> ids, {
    bool includeChapters = false,
  }) async {
    if (ids.isEmpty) return [];

    final offline = !await _hasInternet();
    if (offline) {
      final cached = _cache.getCachedEnrolledCourses();
      if (cached.isNotEmpty) {
        final map = <int, Course>{};
        for (final e in cached) {
          final course = Course.fromJson(e);
          map[course.id] = course;
        }
        return ids.map((id) => map[id]).whereType<Course>().toList();
      }
      throw Exception('No internet connection and no cached courses available.');
    }

    try {
      final response = await _supabase
          .from('course')
          .select(includeChapters ? '*, chapter ( *, lesson (*))' : '*')
          .inFilter('id', ids)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('Courses by IDs fetch timeout'),
          );

      final courses = (response as List<dynamic>)
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();

      if (courses.isNotEmpty) {
        final promotions = await _getPromotionsForCourses(ids);
        for (final course in courses) {
          course.promotions = promotions[course.id] ?? const [];
        }
      }

      await _cache.cacheCourses(courses.map((c) => c.toJson()).toList());
      await _cache.cacheEnrolledCourses(courses.map((c) => c.toJson()).toList());
      return courses;
    } catch (e, stackTrace) {
      developer.log(e.toString(), error: e, stackTrace: stackTrace);
      final cached = _cache.getCachedEnrolledCourses();
      if (cached.isNotEmpty) {
        final map = <int, Course>{};
        for (final e in cached) {
          final course = Course.fromJson(e);
          map[course.id] = course;
        }
        return ids.map((id) => map[id]).whereType<Course>().toList();
      }
      rethrow;
    }
  }

  Future<Map<int, List<Promotion>>> _getPromotionsForCourses(
    List<int> courseIds,
  ) async {
    if (courseIds.isEmpty) return {};

    try {
      final response = await _supabase
          .from('promotion_course')
          .select('promotion:promotion_id(*), course_id')
          .inFilter('course_id', courseIds)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Promotions fetch timeout'),
          );

      final result = <int, List<Promotion>>{};
      for (final item in response as List<dynamic>) {
        final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
        final promotionJson = map['promotion'];
        final courseId = (map['course_id'] as num).toInt();
        if (promotionJson != null) {
          final promotion = Promotion.fromJson(promotionJson as Map<String, dynamic>);
          result.putIfAbsent(courseId, () => []).add(promotion);
        }
      }

      return result;
    } catch (e) {
      developer.log('Failed to load promotions: $e');
      return {};
    }
  }

  Future<void> markLessonComplete(String lessonId, {required bool isComplete}) async {
    await _supabase
        .from('lesson')
        .update({'isComplete': isComplete})
        .eq('id', lessonId)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Lesson update timeout'),
        );
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
