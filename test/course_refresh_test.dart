import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/course_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/enrollment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

Course _course(int id, {bool isFree = false}) => Course(
  id: id,
  title: 'Course $id',
  description: 'desc',
  imageUrl: '',
  progress: 0,
  is_free: isFree,
  status: 'published',
  year: '1st',
  subject: 'Math',
  chapters: const [],
);

class FakeCourseRepository extends CourseRepository {
  FakeCourseRepository(super.client, this.courses);

  List<Course> courses;

  @override
  Future<List<Course>> getCourses({
    int limit = 10,
    int offset = 0,
    String? year,
    String? subject,
    String? type,
    bool includeChapters = true,
  }) async =>
      courses
          .skip(offset)
          .take(limit)
          .where((c) => year == null || year == 'All' || c.year == year)
          .where(
            (c) =>
                subject == null ||
                subject == 'All' ||
                c.subject == subject,
          )
          .where((c) {
            if (type == null || type == 'All') return true;
            if (type == 'Free') return c.is_free;
            return !c.is_free;
          })
          .toList();

  @override
  Future<Course?> getCourseById(int id) async =>
      courses.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<Course>> getCoursesByIds(
    List<int> ids, {
    bool includeChapters = false,
  }) async =>
      courses.where((c) => ids.contains(c.id)).toList();
}

class FakeEnrollmentRepository extends EnrollmentRepository {
  FakeEnrollmentRepository(super.client, this.ids);

  Set<int> ids;

  @override
  Future<Set<int>> getEnrolledCourseIds() async => Set<int>.from(ids);
}

void main() {
  late FakeCourseRepository fakeCourses;
  late FakeEnrollmentRepository fakeEnroll;
  late ProviderContainer container;

  final client = SupabaseClient(
    'https://example.supabase.co',
    'public-anon-key',
  );

  setUp(() {
    fakeCourses = FakeCourseRepository(client, [_course(1), _course(2)]);
    fakeEnroll = FakeEnrollmentRepository(client, {1, 2});
    container = ProviderContainer(
      overrides: [
        courseRepositoryProvider.overrideWithValue(fakeCourses),
        enrollmentRepositoryProvider.overrideWithValue(fakeEnroll),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('My Courses reflects newly added enrolled course after resume refresh',
      () async {
    final notifier = container.read(courseListProvider(true).notifier);

    // Initial load: user is enrolled in courses 1 and 2.
    notifier.setEnrolledCourseIds({1, 2});
    while (notifier.state.isInitialLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    expect(
      notifier.state.courses.map((c) => c.id).toList(),
      containsAll([1, 2]),
    );

    // Admin adds a new course (id 15) and enrolls the user in it.
    fakeCourses.courses = [...fakeCourses.courses, _course(15)];
    fakeEnroll.ids = {1, 2, 15};

    // Simulate app resume: invalidate enrollment cache and re-fetch lists.
    container.invalidate(enrolledCourseIdsProvider);
    notifier.setEnrolledCourseIds({1, 2, 15});
    while (notifier.state.isInitialLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    final shown = notifier.state.courses.map((c) => c.id).toList();
    expect(shown, contains(15),
        reason: 'newly enrolled course must appear without app restart');
  });

  test('courseByIdProvider fetches a newly created course directly', () async {
    // Course 15 does not exist yet.
    expect(await container.read(courseByIdProvider(15).future), isNull);

    // Admin creates course 15.
    fakeCourses.courses = [...fakeCourses.courses, _course(15)];

    // The course details screen is disposed on pop and recreated on
    // navigation (and pull-to-refresh invalidates), so invalidate before
    // the fresh read — it must then reflect the newly created course.
    container.invalidate(courseByIdProvider(15));
    final course = await container.read(courseByIdProvider(15).future);
    expect(course, isNotNull);
    expect(course!.id, 15);
  });

  test('enrolledCourseIdsProvider does not serve a stale cached set', () async {
    final before = await container.read(enrolledCourseIdsProvider.future);
    expect(before, {1, 2});

    fakeEnroll.ids = {1, 2, 3};
    container.invalidate(enrolledCourseIdsProvider);

    final after = await container.read(enrolledCourseIdsProvider.future);
    expect(after, {1, 2, 3});
  });
}
