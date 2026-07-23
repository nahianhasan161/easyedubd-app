import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class EnrollmentRepository {
  final SupabaseClient _supabase;

  EnrollmentRepository(this._supabase);

  Future<Set<int>> getEnrolledCourseIds() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return {};

    final Set<int> courseIds = {};

    final courseEnrollments = await _supabase
        .from('enrollments')
        .select('course_id')
        .eq('profile_id', user.id)
        .eq('status', 'active')
        .not('course_id', 'is', null)
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('Course enrollments timeout'),
        );

    for (final row in courseEnrollments) {
      final id = row['course_id'];
      if (id != null) {
        courseIds.add((id as num).toInt());
      }
    }

    final bundleEnrollments = await _supabase
        .from('enrollments')
        .select('bundle_id')
        .eq('profile_id', user.id)
        .eq('status', 'active')
        .not('bundle_id', 'is', null)
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('Bundle enrollments timeout'),
        );

    final bundleIds = bundleEnrollments
        .map((e) => e['bundle_id'])
        .where((id) => id != null)
        .map((id) => (id as num).toInt())
        .toList();

    if (bundleIds.isNotEmpty) {
      final bundleCourses = await _supabase
          .from('bundle_courses')
          .select('course_id')
          .inFilter('bundle_id', bundleIds)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('Bundle courses timeout'),
          );

      for (final row in bundleCourses) {
        final id = row['course_id'];
        if (id != null) {
          courseIds.add((id as num).toInt());
        }
      }
    }

    return courseIds;
  }

  bool isCourseEnrolled({
    required int courseId,
    required Set<int> enrolledCourseIds,
  }) {
    return enrolledCourseIds.contains(courseId);
  }
}
