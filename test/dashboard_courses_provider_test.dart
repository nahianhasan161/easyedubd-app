import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/course_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/dashboard/providers/dashboard_courses_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Course _course(int id, {String year = '2nd', String subject = 'Chemistry'}) =>
    Course(
      id: id,
      title: 'Course $id',
      description: 'desc',
      imageUrl: '',
      progress: 0,
      is_free: false,
      status: 'published',
      year: year,
      subject: subject,
      chapters: const [],
    );

class _FakeCourseRepository extends CourseRepository {
  _FakeCourseRepository(super.client, this.allCourses);
  List<Course> allCourses;

  @override
  Future<List<Course>> getAllCoursesForOffline({
    int limit = 500,
    bool forceRefresh = false,
  }) async =>
      allCourses;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCourseRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = _FakeCourseRepository(
      SupabaseClient('https://example.supabase.co', 'public-anon-key'),
      [_course(1), _course(2), _course(3)],
    );
    container = ProviderContainer(
      overrides: [
        courseRepositoryProvider.overrideWithValue(fakeRepo),
        // Force "online" so the provider actually fetches.
        connectivityProvider
            .overrideWithValue(AsyncData([ConnectivityResult.wifi])),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'allCoursesForDashboardProvider returns the full unfiltered catalog',
    () async {
      // ignore: unnecessary_cast
      final all = await container
              .read(allCoursesForDashboardProvider.future)
          as List<Course>;
      expect(all.length, 3);
      expect(all.map((c) => c.id), containsAll([1, 2, 3]));
    },
  );

  test(
    'allCoursesForDashboardProvider state is independent of '
    'courseListProvider(false) state',
    () async {
      // Resolve the dashboard provider first.
      // ignore: unnecessary_cast
      final dashboardCourses = await container
              .read(allCoursesForDashboardProvider.future)
          as List<Course>;
      expect(dashboardCourses.length, 3);

      // Now simulate the All Courses tab applying a filter that
      // narrows its own provider to a single course. The dashboard
      // provider must NOT be affected.
      fakeRepo.allCourses = [_course(1)];
      final notifier = container.read(courseListProvider(false).notifier);
      notifier.updateFilters(year: '1st', subject: 'Chemistry');
      // updateFilters calls loadInitial() internally (fire-and-forget),
      // so wait for the notifier to finish its background refetch.
      while (notifier.state.isInitialLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // ignore: unnecessary_cast
      final allCoursesAfter = await container
              .read(allCoursesForDashboardProvider.future)
          as List<Course>;
      expect(
        allCoursesAfter.length,
        3,
        reason:
            'Dashboard must keep showing the full catalog regardless of '
            'what filter the All Courses tab applied.',
      );
    },
  );
}
