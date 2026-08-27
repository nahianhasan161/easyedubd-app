import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The full, unfiltered catalog of courses. Powers the Dashboard tab's
/// "All Courses" and "Recommended" sliders.
///
/// This is intentionally separate from `courseListProvider(false)`,
/// which holds the currently-filtered results of the All Courses tab.
/// When the user changes a filter on the All Courses tab, that provider's
/// state changes, but this one is unaffected — the dashboard always shows
/// the full catalog.
final allCoursesForDashboardProvider =
    AsyncNotifierProvider<AllCoursesForDashboardNotifier, List<Course>>(
  AllCoursesForDashboardNotifier.new,
);

class AllCoursesForDashboardNotifier extends AsyncNotifier<List<Course>> {
  @override
  Future<List<Course>> build() async {
    try {
      // Watch the repository so we re-fetch if the repo instance changes.
      final repo = ref.watch(courseRepositoryProvider);
      return await repo.getAllCoursesForOffline();
    } catch (_) {
      // Never let this provider enter an error state. The Dashboard tab
      // watches it on every build; if it errored, the whole Dashboard
      // would throw "ProviderException: tried to use a provider that is
      // in error state" and the user would see a blank screen. Returning
      // an empty list keeps the UI alive; the user can pull-to-refresh
      // to retry.
      return const <Course>[];
    }
  }

  /// Force a refetch from the network, bypassing the cache.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(courseRepositoryProvider);
      final courses = await repo.getAllCoursesForOffline(forceRefresh: true);
      state = AsyncData(courses);
    } catch (_) {
      // Same reasoning as build(): don't enter error state. Show the
      // last known data (or empty) so the dashboard stays usable.
      state = const AsyncData(<Course>[]);
    }
  }
}
