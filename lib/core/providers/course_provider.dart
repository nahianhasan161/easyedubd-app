import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(Supabase.instance.client);
});
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  ref.keepAlive();
  final repository = ref.read(courseRepositoryProvider);
  return repository.getCourses();
});
