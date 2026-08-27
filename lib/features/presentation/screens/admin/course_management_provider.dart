import 'package:easyedubd_app/features/presentation/screens/admin/course_management_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminCoursesQuery {
  const AdminCoursesQuery({required this.page, this.search});

  final int page;
  final String? search;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminCoursesQuery &&
          other.page == page &&
          other.search == search;

  @override
  int get hashCode => Object.hash(page, search);
}

class AdminChaptersQuery {
  const AdminChaptersQuery({
    required this.courseId,
    required this.page,
    this.search,
  });

  final int courseId;
  final int page;
  final String? search;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminChaptersQuery &&
          other.courseId == courseId &&
          other.page == page &&
          other.search == search;

  @override
  int get hashCode => Object.hash(courseId, page, search);
}

class AdminLessonsQuery {
  const AdminLessonsQuery({
    required this.chapterId,
    required this.page,
    this.search,
  });

  final int chapterId;
  final int page;
  final String? search;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminLessonsQuery &&
          other.chapterId == chapterId &&
          other.page == page &&
          other.search == search;

  @override
  int get hashCode => Object.hash(chapterId, page, search);
}

final adminCoursesProvider =
    FutureProvider.family<PaginatedAdminCourses, AdminCoursesQuery>((ref, query) async {
  final repo = ref.read(adminCourseManagementRepositoryProvider);
  try {
    return await repo.getCourses(page: query.page, search: query.search);
  } catch (_) {
    // Return an empty page on error so the admin screen stays usable.
    // The screen's own error view already handles the loading and error
    // states; this prevents the provider from being permanently stuck in
    // error state across re-fetches.
    return PaginatedAdminCourses(items: const [], total: 0, page: 1, pageSize: 15);
  }
});

final adminChaptersProvider =
    FutureProvider.family<PaginatedAdminChapters, AdminChaptersQuery>((ref, query) async {
  final repo = ref.read(adminCourseManagementRepositoryProvider);
  try {
    return await repo.getChapters(
      courseId: query.courseId,
      page: query.page,
      search: query.search,
    );
  } catch (_) {
    return PaginatedAdminChapters(items: const [], total: 0, page: 1, pageSize: 15);
  }
});

final adminLessonsProvider =
    FutureProvider.family<PaginatedAdminLessons, AdminLessonsQuery>((ref, query) async {
  final repo = ref.read(adminCourseManagementRepositoryProvider);
  try {
    return await repo.getLessons(
      chapterId: query.chapterId,
      page: query.page,
      search: query.search,
    );
  } catch (_) {
    return PaginatedAdminLessons(items: const [], total: 0, page: 1, pageSize: 15);
  }
});
