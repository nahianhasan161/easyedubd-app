import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/course_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

class CourseListState {
  final List<Course> courses;
  final List<Course> allCourses; // Unfiltered list (for client-side filter)
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
    this.allCourses = const [],
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
    List<Course>? allCourses,
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
      allCourses: allCourses ?? this.allCourses,
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

  Future<void> loadInitial({bool forceRefresh = false}) async {
    state = state.copyWith(
      isInitialLoading: true,
      isLoadingMore: false,
      error: null,
      courses: const [],
      page: 0,
      hasMore: true,
    );

    await _fetchPage(0, forceRefresh: forceRefresh);
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

Future<void> _fetchPage(int page, {bool forceRefresh = false}) async {
    final isOffline = ref.read(isOfflineProvider);
    try {
      if (enrolledOnly) {
        final ids = state.enrolledCourseIds;
        final fetched = (ids == null || ids.isEmpty)
            ? <Course>[]
            : await _repository.getCoursesByIds(
                ids.toList(),
                includeChapters: true,
                forceRefresh: forceRefresh,
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
      } else if (isOffline) {
      // OFFLINE: the server-side filter doesn't work, so we use the full
      // unfiltered cached list and apply the filter client-side.
      final all = await _repository.getAllCoursesForOffline(
        forceRefresh: forceRefresh,
      );

      // Apply enrolled filter first.
      final enrolled = state.enrolledCourseIds;
      final withoutEnrolled = enrolled != null && enrolled.isNotEmpty
          ? all.where((c) => !enrolled.contains(c.id)).toList()
          : all;

      // Apply the year / subject / type filter on top.
      final filtered = _applyClientFilters(withoutEnrolled);

      // Simulate pagination: pageSize at a time.
      final start = page * pageSize;
      final end = (start + pageSize).clamp(0, filtered.length);
      final pageItems = start >= filtered.length
          ? <Course>[]
          : filtered.sublist(start, end);
      final hasMoreData = end < filtered.length;

      final courses = page == 0 ? pageItems : [...state.courses, ...pageItems];

      state = state.copyWith(
        allCourses: all,
        courses: courses,
        page: page,
        hasMore: hasMoreData,
        isInitialLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } else {
      // ONLINE: server-side filtering (saves bandwidth on big catalogs).
      // Fetch one extra item to correctly determine if there are more pages
      // after filtering out enrolled courses.
      final rawFetched = await _repository.getCourses(
        limit: pageSize + 1,
        offset: page * pageSize,
        year: state.year,
        subject: state.subject,
        type: state.type,
        includeChapters: false,
        forceRefresh: forceRefresh,
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

      // In the background, also refresh the unfiltered cached list so the
      // user has a full snapshot for offline filter use.
      // Fire and forget; ignore errors.
      if (page == 0) {
        // ignore: discarded_futures
        _repository.getAllCoursesForOffline().catchError((_) {
          return <Course>[];
        });
      }
    }
  } catch (e) {
    // If we already have courses on screen, keep showing them and just
    // surface a soft error message — don't blow the list away because of
    // a transient network blip on a background re-fetch.
    final hasExistingData = state.courses.isNotEmpty;
    developer.log(
      '_fetchPage failed (hasExistingData=$hasExistingData): $e',
      error: e,
    );
    state = state.copyWith(
      isInitialLoading: false,
      isLoadingMore: false,
      // Only show the full error view when we have nothing else to show.
      error: hasExistingData ? null : e.toString(),
    );
  }
}

/// Applies the current year/subject/type filters in-memory.
List<Course> _applyClientFilters(List<Course> source) {
  return source.where((course) {
    if (state.year != 'All' && course.year != state.year) return false;
    if (state.subject != 'All' &&
        course.subject.toLowerCase() != state.subject.toLowerCase()) {
      return false;
    }
    if (state.type == 'Free' && !course.is_free) return false;
    if (state.type == 'Paid' && course.is_free) return false;
    return true;
  }).toList();
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

    final isOffline = ref.read(isOfflineProvider);

    // OFFLINE: the server can't apply the filter, so re-filter the cached
    // full list in memory. No network call needed.
    if (isOffline && state.allCourses.isNotEmpty) {
      final enrolled = state.enrolledCourseIds;
      final withoutEnrolled = enrolled != null && enrolled.isNotEmpty
          ? state.allCourses.where((c) => !enrolled.contains(c.id)).toList()
          : state.allCourses;
      final filtered = _applyClientFilters(withoutEnrolled);

      // Apply just the first page of the filtered list so the UI updates.
      final pageItems = filtered.take(pageSize).toList();
      state = state.copyWith(
        courses: pageItems,
        page: 0,
        hasMore: filtered.length > pageSize,
        isInitialLoading: false,
        isLoadingMore: false,
        error: null,
      );
      return;
    }

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

    // For the "All Courses" tab we already fetched the courses once (without
    // enrolled ids). We can avoid a second network round-trip by simply
    // filtering the already-loaded list in-memory; only trigger a real
    // re-fetch if we don't have any courses yet.
    if (!enrolledOnly) {
      if (state.courses.isEmpty) {
        loadInitial();
      } else {
        // Re-filter the already-fetched list to drop newly-enrolled courses.
        // No network call needed.
        state = state.copyWith(
          courses: state.courses
              .where((c) => !ids.contains(c.id))
              .toList(),
        );
      }
      return;
    }

    // For the "My Courses" tab we genuinely need to fetch the course
    // details for the enrolled ids, so do the full reload.
    loadInitial();
  }
}

final courseListProvider =
    NotifierProvider.family<CourseListNotifier, CourseListState, bool>(
  CourseListNotifier.new,
);
