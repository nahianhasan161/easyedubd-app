import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnrollmentRepository {
  final SupabaseClient _supabase;

  EnrollmentRepository(this._supabase);

  Future<Set<int>> getEnrolledCourseIds() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return {};

    final Set<int> courseIds = {};

    // DIRECT COURSE ENROLLMENTS
    final courseEnrollments = await _supabase
        .from('enrollments')
        .select('course_id')
        .eq('profile_id', user.id)
        .eq('status', 'active')
        .not('course_id', 'is', null);

    for (final row in courseEnrollments) {
      final id = row['course_id'];
      if (id != null) {
        courseIds.add((id as num).toInt()); // ✅ FIX
      }
    }

    // BUNDLE ENROLLMENTS
    final bundleEnrollments = await _supabase
        .from('enrollments')
        .select('bundle_id')
        .eq('profile_id', user.id)
        .eq('status', 'active')
        .not('bundle_id', 'is', null);
    /* debugPrint('🔥 bundleEnrollments RAW: $bundleEnrollments'); */
    final bundleIds = bundleEnrollments
        .map((e) => e['bundle_id'])
        .where((id) => id != null)
        .map((id) => (id as num).toInt())
        .toList();
    /*  debugPrint('📦 extracted bundleIds: $bundleIds'); */
    if (bundleIds.isEmpty) {
      /*  debugPrint('⚠️ No bundle IDs found → skipping bundle course fetch'); */
    } else {
      /* debugPrint('🚀 Fetching bundle courses for: $bundleIds'); */
    }
    if (bundleIds.isNotEmpty) {
      final bundleCourses = await _supabase
          .from('bundle_courses')
          .select('course_id')
          .inFilter('bundle_id', bundleIds);

      for (final row in bundleCourses) {
        debugPrint('➡️ row: $row');
        final id = row['course_id'];
        if (id != null) {
          courseIds.add((id as num).toInt()); // ✅ FIX
        }
      }
      /* debugPrint('✅ FINAL courseIds AFTER BUNDLE: $courseIds'); */
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
