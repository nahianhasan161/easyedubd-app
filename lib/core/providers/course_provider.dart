import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easyedubd_app/core/cache/cache_service.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(Supabase.instance.client);
});

/// Fetches a single course by id.
///
/// The repository is cache-first, so a normal read returns cached data
/// instantly. When the user explicitly requests a refresh (e.g. via
/// pull-to-refresh on the course detail screen), the cache entry for
/// this course is deleted first so the next read falls through to the
/// network. See [refreshCourseById].
final courseByIdProvider =
    FutureProvider.family<Course?, int>((ref, id) async {
  final repository = ref.read(courseRepositoryProvider);
  return repository.getCourseById(id);
});

/// Force-refresh a single course detail. Call this from pull-to-refresh
/// handlers. Deletes the cached entry, invalidates the provider, and
/// waits for fresh data from Supabase.
Future<Course?> refreshCourseById(WidgetRef ref, int id) async {
  // Wipe the cached course detail so the next provider read goes to
  // the network instead of returning the stale cache entry.
  final cacheKey = CacheService.courseKey(courseId: id);
  await CacheService.deleteCourse(cacheKey);
  ref.invalidate(courseByIdProvider(id));
  return ref.read(courseByIdProvider(id).future);
}
