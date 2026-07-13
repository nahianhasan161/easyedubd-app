import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/enrollment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository(Supabase.instance.client);
});

final enrolledCourseIdsProvider = FutureProvider<Set<int>>((ref) async {
  return ref.read(enrollmentRepositoryProvider).getEnrolledCourseIds();
});
