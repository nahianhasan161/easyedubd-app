import 'package:easyedubd_app/features/presentation/screens/admin/course_management_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/course_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoursesQuery {
  const CoursesQuery({required this.page, this.search});

  final int page;
  final String? search;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoursesQuery &&
          other.page == page &&
          other.search == search;

  @override
  int get hashCode => Object.hash(page, search);
}

class EnrollmentsQuery {
  const EnrollmentsQuery({
    required this.page,
    this.search,
    this.courseId,
    this.profileId,
  });

  final int page;
  final String? search;
  final int? courseId;
  final String? profileId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnrollmentsQuery &&
          other.page == page &&
          other.search == search &&
          other.courseId == courseId &&
          other.profileId == profileId;

  @override
  int get hashCode => Object.hash(page, search, courseId, profileId);
}

final coursesProvider =
    FutureProvider.family<PaginatedCourses, CoursesQuery>((ref, query) {
  return ref
      .read(adminCourseRepositoryProvider)
      .getCourses(page: query.page, search: query.search);
});

final enrollmentsProvider =
    FutureProvider.family<PaginatedEnrollments, EnrollmentsQuery>((ref, query) {
  return ref
      .read(adminCourseRepositoryProvider)
      .getEnrollments(page: query.page, search: query.search, courseId: query.courseId, profileId: query.profileId);
});

final userSearchProvider =
    FutureProvider.family<List<Profile>, String>((ref, term) {
  return ref.read(adminCourseRepositoryProvider).searchUsers(term);
});
