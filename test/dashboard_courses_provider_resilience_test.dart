import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/course_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/dashboard/providers/dashboard_courses_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeCourseRepository extends CourseRepository {
  _FakeCourseRepository(super.client, this.allCourses);
  List<Course> allCourses;
  bool shouldThrow = false;

  @override
  Future<List<Course>> getAllCoursesForOffline({
    int limit = 500,
    bool forceRefresh = false,
  }) async {
    if (shouldThrow) {
      throw Exception('Simulated network failure');
    }
    return allCourses;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCourseRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = _FakeCourseRepository(
      SupabaseClient('https://example.supabase.co', 'public-anon-key'),
      [_course(1), _course(2)],
    );
    container = ProviderContainer(
      overrides: [
        courseRepositoryProvider.overrideWithValue(fakeRepo),
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
      expect(all.length, 2);
    },
  );

  test(
    'allCoursesForDashboardProvider does NOT enter error state on '
    'build() failure — returns empty list instead',
    () async {
      fakeRepo.shouldThrow = true;
      // Force a re-build by invalidating.
      container.invalidate(allCoursesForDashboardProvider);
      // ignore: unnecessary_cast
      final all = await container
              .read(allCoursesForDashboardProvider.future)
          as List<Course>;
      expect(
        all,
        isEmpty,
        reason: 'Provider must not enter error state — it should return an '
            'empty list so the dashboard stays usable.',
      );
    },
  );

  test(
    'allCoursesForDashboardProvider.refresh() does NOT enter error state '
    'on failure — returns AsyncData with empty list',
    () async {
      fakeRepo.shouldThrow = true;
      await container.read(allCoursesForDashboardProvider.notifier).refresh();
      final state = container.read(allCoursesForDashboardProvider);
      expect(
        state,
        isA<AsyncData<List<Course>>>(),
        reason: 'After a failed refresh, the state must be AsyncData, '
            'not AsyncError.',
      );
      expect((state as AsyncData<List<Course>>).value, isEmpty);
    },
  );
}

Course _course(int id) => Course(
      id: id,
      title: 'Course $id',
      description: 'desc',
      imageUrl: '',
      progress: 0,
      is_free: false,
      status: 'published',
      year: '1st',
      subject: 'Math',
      chapters: const [],
    );
