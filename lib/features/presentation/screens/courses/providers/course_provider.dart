import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/enrollment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository(Supabase.instance.client);
});

final enrolledCourseIdsProvider = FutureProvider<Set<int>>((ref) async {
  return ref.read(enrollmentRepositoryProvider).getEnrolledCourseIds();
});

Future<void> refreshStudentCourseCaches(WidgetRef ref) async {
  ref.invalidate(courseListProvider(false));
  ref.invalidate(courseListProvider(true));
  ref.invalidate(enrolledCourseIdsProvider);

  final enrolledIds = await ref.read(enrolledCourseIdsProvider.future);

  final allNotifier = ref.read(courseListProvider(false).notifier);
  final myNotifier = ref.read(courseListProvider(true).notifier);

  allNotifier.setEnrolledCourseIds(enrolledIds);
  myNotifier.setEnrolledCourseIds(enrolledIds);
}
