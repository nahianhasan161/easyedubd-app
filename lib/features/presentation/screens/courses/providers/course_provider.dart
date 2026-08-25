import 'package:easyedubd_app/core/cache/cache_service.dart';
import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/enrollment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository(Supabase.instance.client);
});

final enrolledCourseIdsProvider = FutureProvider<Set<int>>((ref) async {
  // When offline, skip the network call entirely. The repository's own
  // cache check will return cached data; if there is none we return an
  // empty set so the UI doesn't get stuck waiting on a 8s timeout.
  final isOffline = ref.watch(isOfflineProvider);
  if (isOffline) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final cached =
          CacheService.getEnrollment(CacheService.enrollmentKey(user.id));
      if (cached != null) {
        return Set<int>.from((cached as List).cast<int>());
      }
    }
    return <int>{};
  }
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
