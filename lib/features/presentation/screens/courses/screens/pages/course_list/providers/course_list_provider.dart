import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/course_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseListState {
  final List<Course> courses;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int page;
  final String year;
  final String subject;
  final String type;
  final Set<int>? enrolledCourseIds;

  const CourseListState({
    this.courses = const [],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.page = 0,
    this.year = 'All',
    this.subject = 'All',
    this.type = 'All',
    this.enrolledCourseIds,
  });

  CourseListState copyWith({
    List<Course>? courses,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? page,
    String? year,
    String? subject,
    String? type,
    Set<int>? enrolledCourseIds,
  }) {
    return CourseListState(
      courses: courses ?? this.courses,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      page: page ?? this.page,
      year: year ?? this.year,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      enrolledCourseIds: enrolledCourseIds ?? this.enrolledCourseIds,
    );
  }
}

class CourseListNotifier extends Notifier<CourseListState> {
  CourseListNotifier(this.enrolledOnly);

  final bool enrolledOnly;

  late final CourseRepository _repository;

  @override
  CourseListState build() {
    _repository = ref.read(courseRepositoryProvider);
    return const CourseListState();
  }

  static const int pageSize = 10;

  Future<void> loadInitial() async {
    if (state.isInitialLoading) return;

    state = state.copyWith(
      isInitialLoading: true,
      isLoadingMore: false,
      error: null,
      courses: const [],
      page: 0,
      hasMore: true,
    );

    await _fetchPage(0);
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.error != null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);
    await _fetchPage(state.page + 1);
  }

  Future<void> _fetchPage(int page) async {
    try {
      List<Course> fetched;

      if (enrolledOnly) {
        // Fetch the enrolled courses directly by id (server-side) so they are
        // always retrieved regardless of their position in the full list.
        final ids = state.enrolledCourseIds;
        fetched = (ids == null || ids.isEmpty)
            ? []
            : await _repository.getCoursesByIds(
                ids.toList(),
                includeChapters: false,
              );
      } else {
        fetched = await _repository.getCourses(
          limit: pageSize,
          offset: page * pageSize,
          year: state.year,
          subject: state.subject,
          type: state.type,
          includeChapters: false,
        );

        // Hide enrolled courses from the "All Courses" tab so they only
        // appear under "My Courses".
        final enrolled = state.enrolledCourseIds;
        if (enrolled != null && enrolled.isNotEmpty) {
          fetched =
              fetched.where((course) => !enrolled.contains(course.id)).toList();
        }
      }

      final courses = page == 0 ? fetched : [...state.courses, ...fetched];

      state = state.copyWith(
        courses: courses,
        page: page,
        // "My Courses" is fetched in full (no pagination).
        hasMore: !enrolledOnly && fetched.length == pageSize,
        isInitialLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void updateFilters({String? year, String? subject, String? type}) {
    final nextYear = year ?? state.year;
    final nextSubject = subject ?? state.subject;
    final nextType = type ?? state.type;

    if (nextYear == state.year &&
        nextSubject == state.subject &&
        nextType == state.type) {
      return;
    }

    state = state.copyWith(
      year: nextYear,
      subject: nextSubject,
      type: nextType,
    );

    loadInitial();
  }

  void setEnrolledCourseIds(Set<int> ids) {
    final current = state.enrolledCourseIds;

    if (current != null &&
        current.length == ids.length &&
        current.containsAll(ids)) {
      return;
    }

    state = state.copyWith(enrolledCourseIds: ids);

    // Reload both tabs so enrolled courses disappear from "All Courses"
    // and appear in "My Courses" as soon as the ids arrive.
    loadInitial();
  }
}

final courseListProvider =
    NotifierProvider.family<CourseListNotifier, CourseListState, bool>(
  CourseListNotifier.new,
);
