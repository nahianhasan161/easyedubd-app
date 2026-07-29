import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';

class LocalCacheService {
  static const String profileBox = 'profileBox';
  static const String courseBox = 'courseBox';
  static const String enrollmentBox = 'enrollmentBox';
  static const String enrolledCourseCacheBox = 'enrolledCourseCacheBox';

  Box<dynamic> get _profileBox => Hive.box(profileBox);
  Box<dynamic> get _courseBox => Hive.box(courseBox);
  Box<dynamic> get _enrollmentBox => Hive.box(enrollmentBox);
  Box<dynamic> get _enrolledCourseCacheBox => Hive.box(enrolledCourseCacheBox);

  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    try {
      await _profileBox.put('current', profile);
      await _profileBox.flush();
    } catch (e, st) {
      developer.log('cacheProfile failed', error: e, stackTrace: st);
    }
  }

  Map<String, dynamic>? getCachedProfile() {
    try {
      final data = _profileBox.get('current');
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (e, st) {
      developer.log('getCachedProfile failed', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> cacheCourses(List<Map<String, dynamic>> courses) async {
    try {
      final existing = _courseBox.get('all');
      final Map<int, Map<String, dynamic>> merged = {};

      if (existing is List) {
        for (final item in existing) {
          if (item is Map) {
            final id = item['id'];
            if (id != null) merged[(id as num).toInt()] = Map<String, dynamic>.from(item);
          }
        }
      }

      for (final course in courses) {
        final id = course['id'];
        if (id != null) merged[(id as num).toInt()] = course;
      }

      await _courseBox.put('all', merged.values.toList());
      await _courseBox.flush();
      developer.log('Cached/merged ${merged.length} courses to general cache');
    } catch (e, st) {
      developer.log('cacheCourses failed', error: e, stackTrace: st);
    }
  }

  List<Map<String, dynamic>> getCachedCourses() {
    try {
      final data = _courseBox.get('all');
      if (data is List) {
        final result = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        developer.log('Loaded ${result.length} courses from general cache');
        return result;
      }
      developer.log('General course cache is empty or not a list');
      return [];
    } catch (e, st) {
      developer.log('getCachedCourses failed', error: e, stackTrace: st);
      return [];
    }
  }

  Future<void> cacheCourseById(Map<String, dynamic> course) async {
    try {
      final id = course['id'];
      if (id == null) return;
      await _courseBox.put('course_$id', course);
      await _courseBox.flush();
    } catch (e, st) {
      developer.log('cacheCourseById failed', error: e, stackTrace: st);
    }
  }

  Map<String, dynamic>? getCachedCourseById(int id) {
    try {
      final data = _courseBox.get('course_$id');
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (e, st) {
      developer.log('getCachedCourseById failed', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> cacheEnrolledCourseIds(Set<int> ids) async {
    try {
      await _enrollmentBox.put('ids', ids.toList());
      await _enrollmentBox.flush();
    } catch (e, st) {
      developer.log('cacheEnrolledCourseIds failed', error: e, stackTrace: st);
    }
  }

  Set<int> getCachedEnrolledCourseIds() {
    try {
      final data = _enrollmentBox.get('ids');
      if (data is List) return data.whereType<int>().toSet();
      return <int>{};
    } catch (e, st) {
      developer.log('getCachedEnrolledCourseIds failed', error: e, stackTrace: st);
      return <int>{};
    }
  }

  Future<void> cacheEnrolledCourses(List<Map<String, dynamic>> courses) async {
    try {
      await _enrolledCourseCacheBox.put('enrolled', courses);
      await _enrolledCourseCacheBox.flush();
      developer.log('Cached ${courses.length} enrolled courses');
    } catch (e, st) {
      developer.log('cacheEnrolledCourses failed', error: e, stackTrace: st);
    }
  }

  List<Map<String, dynamic>> getCachedEnrolledCourses() {
    try {
      final data = _enrolledCourseCacheBox.get('enrolled');
      if (data is List) {
        final result = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        developer.log('Loaded ${result.length} enrolled courses from cache');
        return result;
      }
      developer.log('Enrolled course cache is empty or not a list');
      return [];
    } catch (e, st) {
      developer.log('getCachedEnrolledCourses failed', error: e, stackTrace: st);
      return [];
    }
  }

  Future<void> clearAll() async {
    try {
      await _profileBox.clear();
      await _courseBox.clear();
      await _enrollmentBox.clear();
      await _enrolledCourseCacheBox.clear();
    } catch (e, st) {
      developer.log('clearAll failed', error: e, stackTrace: st);
    }
  }
}
