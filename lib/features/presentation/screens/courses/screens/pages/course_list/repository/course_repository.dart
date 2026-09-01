import 'dart:async';

import 'package:easyedubd_app/core/cache/cache_service.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/promotion.dart';
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
    bool forceRefresh = false,
    String? search,
  }) async {
    final trimmedSearch = (search == null || search.trim().isEmpty)
        ? null
        : search.trim();
    final cacheKey = CacheService.courseKey(
      year: year,
      subject: subject,
      type: type,
      offset: offset,
      limit: limit,
      includeChapters: includeChapters,
      search: trimmedSearch,
    );

    // Try cache first (unless caller forced a network refresh, e.g. the
    // user pulled-to-refresh). If the cached payload is corrupt (e.g. from
    // an older app version or a partially-written entry) we drop it and
    // fall through to the network call instead of crashing the whole list.
    if (!forceRefresh) {
      final cached = CacheService.getCourse(cacheKey);
      if (cached != null) {
        try {
          final cacheMap = cached as Map;
          // Hive returns nested maps as Map<dynamic,dynamic> which breaks
          // `Map<String, dynamic>` casts downstream — normalize first.
          final data = (CacheService.normalize(cacheMap['data']) as List)
              .cast<Map<String, dynamic>>();
          final cachedAt = cacheMap['cachedAt'] as int?;
          final age = cachedAt == null
              ? const Duration(days: 999)
              : DateTime.now()
                  .difference(DateTime.fromMillisecondsSinceEpoch(cachedAt));
          developer.log(
            'Cache hit for $cacheKey (age: ${age.inSeconds}s, ${data.length} items)',
          );
          return data.map((json) => Course.fromJson(json)).toList();
        } catch (e) {
          developer.log('Corrupt cache entry for $cacheKey, dropping: $e');
          await CacheService.deleteCourse(cacheKey);
        }
      }
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

      if (trimmedSearch != null) {
        // PostgREST: escape % and _ so user input is treated literally, then
        // wrap in %...% for substring match across title and description.
        final escaped = trimmedSearch
            .replaceAll('\\', '\\\\')
            .replaceAll('%', '\\%')
            .replaceAll('_', '\\_');
        final pattern = '%$escaped%';
        query = query.or('title.ilike.$pattern,description.ilike.$pattern');
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

      // Cache the raw response so it can be served offline / avoid future fetches.
      try {
        await CacheService.putCourse(cacheKey, {
          'data': response,
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        developer.log('Failed to cache courses for $cacheKey: $e');
      }

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

      return courses;
    } catch (e, stackTrace) {
      developer.log('getCourses failed: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Course?> getCourseById(
    int id, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = CacheService.courseKey(courseId: id);

    // Try cache first (unless forceRefresh is set). This is what enables
    // offline course detail viewing.
    if (!forceRefresh) {
      final cached = CacheService.getCourse(cacheKey);
      if (cached != null) {
        try {
          developer.log('Cache hit for course $id');
          return Course.fromJson(
            CacheService.normalize(cached) as Map<String, dynamic>,
          );
        } catch (e) {
          developer.log('Corrupt cache entry for course $id, dropping: $e');
          await CacheService.deleteCourse(cacheKey);
        }
      }
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

      // Cache the full course detail for offline access.
      await CacheService.putCourse(cacheKey, courseJson);

      return Course.fromJson(courseJson);
    } catch (e, stackTrace) {
      developer.log(e.toString(), error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Course>> getCoursesByIds(
    List<int> ids, {
    bool includeChapters = false,
    bool forceRefresh = false,
  }) async {
    if (ids.isEmpty) return [];
    final cacheKey =
        'courses_by_ids_${ids.join('_')}_$includeChapters';

    // Try cache first (unless caller forced a network refresh).
    if (!forceRefresh) {
      final cached = CacheService.getCourse(cacheKey);
      if (cached != null) {
        try {
          final cacheMap = cached as Map;
          final data = (CacheService.normalize(cacheMap['data']) as List)
              .cast<Map<String, dynamic>>();
          return data.map((json) => Course.fromJson(json)).toList();
        } catch (e) {
          developer.log('Corrupt cache entry for $cacheKey, dropping: $e');
          await CacheService.deleteCourse(cacheKey);
        }
      }
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

      // Cache the raw response
      await CacheService.putCourse(cacheKey, {
        'data': response,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      });

      final courses = (response as List<dynamic>)
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();

      if (courses.isNotEmpty) {
        final promotions = await _getPromotionsForCourses(ids);
        for (final course in courses) {
          course.promotions = promotions[course.id] ?? const [];
        }
      }

      return courses;
    } catch (e, stackTrace) {
      developer.log(e.toString(), error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Fetches a large unfiltered list of courses and caches it under a
  /// dedicated key. This is used as the "master" dataset that we filter
  /// client-side when the user is offline (since the server-side filter
  /// doesn't work without connectivity).
  ///
  /// When online this still goes to Supabase (and caches the result).
  /// When offline it returns whatever is already cached, or an empty list
  /// if the cache is empty.
  Future<List<Course>> getAllCoursesForOffline({
    int limit = 500,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'courses_all_offline';

    // Try cache first (unless caller forced a network refresh, e.g. the
    // user pulled-to-refresh in the course list).
    if (!forceRefresh) {
      final cached = CacheService.getCourse(cacheKey);
      if (cached != null) {
        try {
          final cacheMap = cached as Map;
          final data = (CacheService.normalize(cacheMap['data']) as List)
              .cast<Map<String, dynamic>>();
          return data.map((json) => Course.fromJson(json)).toList();
        } catch (e) {
          developer.log('Corrupt cache entry for $cacheKey, dropping: $e');
          await CacheService.deleteCourse(cacheKey);
        }
      }
    }

    try {
      final response = await _supabase
          .from('course')
          .select('*')
          .order('position', ascending: true)
          .order('created_at', ascending: true)
          .limit(limit)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('All courses fetch timeout'),
          );

      // Cache the raw response
      try {
        await CacheService.putCourse(cacheKey, {
          'data': response,
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        developer.log('Failed to cache all-courses for $cacheKey: $e');
      }

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

      return courses;
    } catch (e, stackTrace) {
      developer.log(
        'getAllCoursesForOffline failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
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
}

