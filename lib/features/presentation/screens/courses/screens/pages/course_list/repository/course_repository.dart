import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer; // Required for the log() function
import 'dart:convert';

class CourseRepository {
  final SupabaseClient _supabase;

  CourseRepository(this._supabase);

  Future<List<Course>> getCourses() async {
    try {
      final response = await _supabase
          .from('course')
          .select('''
      *,
      chapter (
        *,
        lesson (*))
    ''')
          .order('position', ascending: true)
          .order('created_at', ascending: true)
          .order('position', referencedTable: 'chapter', ascending: true)
          .order('created_at', referencedTable: 'chapter', ascending: true)
          .order(
            'position  ',
            referencedTable: 'chapter.lesson',
            ascending: true,
          )
          .order(
            'created_at',
            referencedTable: 'chapter.lesson',
            ascending: true,
          );

      developer.log(
        const JsonEncoder.withIndent('  ').convert(response),

        name: 'Supabase Response',
      );
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
