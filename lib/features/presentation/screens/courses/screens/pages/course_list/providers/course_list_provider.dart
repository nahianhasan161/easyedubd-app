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
    return const CourseListState(isInitialLoading: true);
  }

  static const int pageSize = 10;

  Future<void> loadInitial() async {
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
       if (enrolledOnly) {
         final ids = state.enrolledCourseIds;
         final fetched = (ids == null || ids.isEmpty)
             ? <Course>[]
             : await _repository.getCoursesByIds(
                 ids.toList(),
                 includeChapters: true,
               );

         final courses = page == 0 ? fetched : [...state.courses, ...fetched];

         state = state.copyWith(
           courses: courses,
           page: page,
           hasMore: false, // No pagination for enrolled-only tab
           isInitialLoading: false,
           isLoadingMore: false,
           error: null,
         );
       } else {
         // Fetch one extra item to correctly determine if there are more pages
         // after filtering out enrolled courses
         final rawFetched = await _repository.getCourses(
           limit: pageSize + 1,
           offset: page * pageSize,
           year: state.year,
           subject: state.subject,
           type: state.type,
           includeChapters: false,
         );

         // Hide enrolled courses from the "All Courses" tab so they only
         // appear under "My Courses".
         final enrolled = state.enrolledCourseIds;
         final fetched = enrolled != null && enrolled.isNotEmpty
             ? rawFetched.where((course) => !enrolled.contains(course.id)).toList()
             : rawFetched;

         // Determine if there are more pages: we fetched pageSize + 1 from the API.
         // If we got exactly pageSize + 1, there are more pages available.
         // If we got less than or equal to pageSize, we've reached the end.
         final hasMoreData = rawFetched.length == pageSize + 1;

         final courses = page == 0 ? fetched : [...state.courses, ...fetched];

         state = state.copyWith(
           courses: courses,
           page: page,
           hasMore: hasMoreData,
           isInitialLoading: false,
           isLoadingMore: false,
           error: null,
         );
       }
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
