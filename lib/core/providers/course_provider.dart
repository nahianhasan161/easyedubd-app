import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(Supabase.instance.client);
});

/// Fetches a single course by id directly from Supabase.
/// Unlike a cached full-list snapshot, this always reflects the latest data,
/// so newly created courses are visible immediately.
final courseByIdProvider =
    FutureProvider.family<Course?, int>((ref, id) async {
  final repository = ref.read(courseRepositoryProvider);
  return repository.getCourseById(id);
});
