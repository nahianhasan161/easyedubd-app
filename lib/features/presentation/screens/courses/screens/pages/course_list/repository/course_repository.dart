import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer; // Required for the log() function

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

      final response = await ordered.range(offset, offset + limit - 1);

      /* print(const JsonEncoder.withIndent('  ').convert(response)); */
      // The response is already a List<dynamic> from the Supabase SDK
      return (response as List<dynamic>)
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      // Log the error (e.g., using logger package or print)
      developer.log(e.toString(), error: e, stackTrace: stackTrace);
      // Return an empty list or rethrow depending on your error handling policy
      rethrow;
    }
  }
}
