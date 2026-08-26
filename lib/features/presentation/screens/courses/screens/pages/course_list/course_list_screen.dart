import 'dart:async';

import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/core/network/retry.dart';
import 'package:easyedubd_app/core/router/app_router.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:easyedubd_app/features/presentation/screens/courses/widgets/course_card.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  final bool enrolledOnly;
  final bool showAppBar;

  const CourseListScreen({
    super.key,
    this.enrolledOnly = false,
    this.showAppBar = true,
  });

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> with RouteAware {
  final ScrollController _scrollController = ScrollController();
  Timer? _loadRetryTimer;
  bool _showLoadRetry = false;
  bool _refreshScheduled = false;

  late String selectedYear;
  late String selectedSubject;
  late String selectedType;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();

    selectedYear = 'All';
    selectedSubject = 'All';
    selectedType = 'All';

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final notifier = ref.read(
        courseListProvider(widget.enrolledOnly).notifier,
      );

      final idsAsync = ref.read(enrolledCourseIdsProvider);
      if (idsAsync.hasValue) {
        notifier.setEnrolledCourseIds(idsAsync.value ?? {});
      } else {
        idsAsync.whenData((ids) => notifier.setEnrolledCourseIds(ids));
      }

      notifier.loadInitial();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleRefreshIfNeeded();
  }

  @override
  void dispose() {
    final routeObserver = ref.read(routeObserverProvider);
    routeObserver.unsubscribe(this);
    _loadRetryTimer?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // When offline, don't trigger a refetch — the cache is still valid and
    // the user expects to see their previously-loaded courses. A refetch
    // while offline would force a network call that hangs on DNS timeout.
    if (ref.read(isOfflineProvider)) return;
    _scheduleRefreshIfNeeded();
  }

  void _scheduleRefreshIfNeeded() {
    if (!widget.enrolledOnly) return;
    if (!mounted) return;
    if (_refreshScheduled) return;

    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _refreshScheduled = false;
      if (!mounted) return;
      await _refreshCourses();
    });
  }

  void _resetLoadRetry() {
    _loadRetryTimer?.cancel();
    _loadRetryTimer = null;
    _showLoadRetry = false;
  }

  void _startLoadTimerIfNeeded() {
    if (_loadRetryTimer != null) return;
    if (!mounted) return;
    final courseList = ref.read(courseListProvider(widget.enrolledOnly));
    if (!courseList.isInitialLoading) return;

    _showLoadRetry = false;
    _loadRetryTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() => _showLoadRetry = true);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(courseListProvider(widget.enrolledOnly).notifier).loadMore();
    }
  }

  Widget _buildFilterDropdown({
    required String label,
    required List<String> options,
    required String selected,
    required void Function(String) onSelected,
    String? allLabel,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isActive = selected != 'All';
    final defaultText = allLabel ?? 'All';

    // Display label for the "All" option so users know what the filter is.
    String display(String option) => option == 'All' ? defaultText : option;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isActive ? primary : Colors.grey.shade300),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isActive
                ? theme.colorScheme.onPrimary
                : Colors.grey.shade700,
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                display(option),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive && option == selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: isActive && option == selected ? primary : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            onSelected(value);
          },
          selectedItemBuilder: (context) {
            return options.map((option) {
              final active = option != 'All';
              return Text(
                display(option),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? theme.colorScheme.onPrimary
                      : Colors.grey.shade700,
                ),
              );
            }).toList();
          },
          style: TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
          dropdownColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildTopFilters() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final notifier = ref.read(courseListProvider(widget.enrolledOnly).notifier);

    Widget searchField() {
      return TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => notifier.setSearchQuery(value),
        decoration: const InputDecoration(
          hintText: 'Search courses...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(fontSize: 14),
        textInputAction: TextInputAction.search,
      );
    }

    Widget dropdownScroll() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterDropdown(
              label: 'Year',
              allLabel: 'Year',
              options: const ['All', '1st', '2nd', '3rd', '4th'],
              selected: selectedYear,
              onSelected: (value) {
                setState(() => selectedYear = value);
                ref
                    .read(courseListProvider(widget.enrolledOnly).notifier)
                    .updateFilters(year: value);
              },
            ),
            const SizedBox(width: 8),
            _buildFilterDropdown(
              label: 'Subject',
              allLabel: 'Subject',
              options: const [
                'All',
                'Math',
                'Physics',
                'Chemistry',
                'Biology'
              ],
              selected: selectedSubject,
              onSelected: (value) {
                setState(() => selectedSubject = value);
                ref
                    .read(courseListProvider(widget.enrolledOnly).notifier)
                    .updateFilters(subject: value);
              },
            ),
            const SizedBox(width: 8),
            _buildFilterDropdown(
              label: 'Type',
              allLabel: 'Type',
              options: const ['All', 'Free', 'Paid'],
              selected: selectedType,
              onSelected: (value) {
                setState(() => selectedType = value);
                ref
                    .read(courseListProvider(widget.enrolledOnly).notifier)
                    .updateFilters(type: value);
              },
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isSearchExpanded ? Icons.search : Icons.filter_list,
            size: 20,
            color: primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isSearchExpanded
                  ? KeyedSubtree(
                      key: const ValueKey('search-field'),
                      child: searchField(),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('filter-scroll'),
                      child: dropdownScroll(),
                    ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
              });
              if (_isSearchExpanded) {
                // Request focus after the AnimatedSwitcher has mounted the
                // TextField so the keyboard comes up immediately.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _searchFocusNode.requestFocus();
                });
              } else {
                _searchFocusNode.unfocus();
                if (_searchController.text.isNotEmpty) {
                  _searchController.clear();
                  notifier.setSearchQuery('');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _isSearchExpanded
                    ? primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isSearchExpanded ? Icons.close : Icons.search,
                size: 20,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshCourses() async {
    // Always invalidate the enrollment set so the in-memory "filter out
    // enrolled courses" pass inside _fetchPage doesn't accidentally hide a
    // newly-created course with a stale cached enrollment list (e.g. the
    // admin who created the course was auto-enrolled in it, or the new
    // course is covered by a bundle the user is in). We then wait for the
    // freshest value to land before the force-refetch so the filter uses
    // up-to-date data.
    ref.invalidate(enrolledCourseIdsProvider);
    try {
      await ref.read(enrolledCourseIdsProvider.future);
    } catch (_) {
      // If the network call fails (offline, timeout) we still proceed with
      // whatever enrollment data is currently in state — the catch in
      // _fetchPage will keep the existing list visible.
    }

    await ref
        .read(courseListProvider(widget.enrolledOnly).notifier)
        .loadInitial(forceRefresh: true);

    if (mounted) {
      _startLoadTimerIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeObserver = ref.read(routeObserverProvider);
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);

    final courseList = ref.watch(courseListProvider(widget.enrolledOnly));
    final isOffline = ref.watch(isOfflineProvider);

    if (courseList.isInitialLoading) {
      _startLoadTimerIfNeeded();
    } else {
      _resetLoadRetry();
    }

    ref.listen(enrolledCourseIdsProvider, (previous, next) {
      next.whenData(
        (ids) => ref
            .read(courseListProvider(widget.enrolledOnly).notifier)
            .setEnrolledCourseIds(ids),
      );
    });

    final loadingBody = RefreshIndicator(
      onRefresh: _refreshCourses,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
           SliverPadding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                 (context, index) {
                   return Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Row(
                         children: [
                           Expanded(
                               child: CourseCardSkeleton(isCompact: true)),
                           const SizedBox(width: 12),
                           Expanded(
                               child: CourseCardSkeleton(isCompact: true)),
                         ],
                       ),
                       const SizedBox(height: 12),
                     ],
                   );
                 },
                childCount: 3,
              ),
            ),
          ),
          if (_showLoadRetry)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Taking too long?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your connection',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () {
                            _refreshCourses();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final listChild = courseList.courses.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              Center(child: Text('No courses found.')),
            ],
          )
        : CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
               SliverPadding(
                 padding:
                     const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final startIndex = index * 2;
                      final course1 = courseList.courses[startIndex];
                      final course2 = startIndex + 1 < courseList.courses.length
                          ? courseList.courses[startIndex + 1]
                          : null;

                      final isEnrolled1 = widget.enrolledOnly ||
                          courseList.enrolledCourseIds
                              ?.contains(course1.id) == true;

                      Widget buildCard(Course course, bool isEnrolled) {
                        return CourseCard(
                          course: course,
                          isEnrolled: isEnrolled || course.is_free,
                          isCompact: true,
                          onTap: () {
                            context.push('/course/${course.id}');
                          },
                          onEnroll: () {
                            context.push('/course/${course.id}');
                          },
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: buildCard(
                                  course1,
                                  isEnrolled1 || course1.is_free,
                                ),
                              ),
                              if (course2 != null) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: buildCard(
                                    course2,
                                    widget.enrolledOnly ||
                                        courseList.enrolledCourseIds
                                            ?.contains(course2.id) == true ||
                                        course2.is_free,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                    childCount: (courseList.courses.length / 2).ceil(),
                  ),
                ),
              ),
              if (courseList.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );

    final child = _selectBody(
      context: context,
      courseList: courseList,
      isOffline: isOffline,
      loadingBody: loadingBody,
      listChild: listChild,
    );

    final body = RefreshIndicator(
      onRefresh: _refreshCourses,
      child: child,
    );

    final content = Column(
      children: [
        if (!widget.enrolledOnly) _buildTopFilters(),
        if (isOffline) _buildOfflineBanner(),
        Expanded(child: body),
      ],
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.enrolledOnly ? 'My Courses' : 'All Courses'),
        centerTitle: false,
        elevation: 0,
        bottom: isOffline && widget.enrolledOnly
            ? PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: _buildOfflineBanner(),
              )
            : null,
      ),
      body: content,
    );
  }

  /// Amber banner shown when the device is offline. Sits below the filter
  /// row on "All Courses" and below the AppBar on "My Courses" so the
  /// user can see both the banner and the content it refers to.
  Widget _buildOfflineBanner() {
    return Material(
      color: Colors.amber.shade700,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: const [
              Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No internet — showing cached data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Decides which body to render. When the user is offline we deliberately
  /// avoid showing the spinner or the "Could not load courses" error — those
  /// only make sense while we are actively trying to reach Supabase. Instead
  /// we show a calm offline notice, and the cached data (if any) above it.
  Widget _selectBody({
    required BuildContext context,
    required CourseListState courseList,
    required bool isOffline,
    required Widget loadingBody,
    required Widget listChild,
  }) {
    // While online, keep the existing behaviour: spinner → error → list.
    if (!isOffline) {
      if (courseList.isInitialLoading) return loadingBody;
      if (courseList.error != null) return _buildErrorView(context, courseList);
      return listChild;
    }

    // Offline path.
    if (courseList.courses.isNotEmpty) {
      // Cached courses are available — show them with a small note.
      return Stack(
        children: [
          listChild,
          if (courseList.isLoadingMore)
            const Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    }

    if (courseList.isInitialLoading) {
      return _buildOfflineMessage(
        context,
        title: widget.enrolledOnly
            ? 'Loading your courses…'
            : 'Loading courses…',
        message: widget.enrolledOnly
            ? 'We couldn\'t read your enrolled courses from cache. Reconnect to retry.'
            : 'We couldn\'t read the course list from cache. Reconnect to load fresh data.',
        showSpinner: true,
      );
    }

    if (courseList.error != null) {
      return _buildOfflineMessage(
        context,
        title: 'You\'re offline',
        message: widget.enrolledOnly
            ? 'No cached enrollment data is available. Reconnect to see your courses.'
            : 'No cached courses are available. Reconnect to browse the catalog.',
        showSpinner: false,
      );
    }

    // Offline and no error and not loading — empty cache.
    return _buildOfflineMessage(
      context,
      title: 'Nothing cached yet',
      message: widget.enrolledOnly
          ? 'Open this tab while online at least once to cache your courses for offline use.'
          : 'Open this tab while online at least once to cache courses for offline browsing.',
      showSpinner: false,
    );
  }

  Widget _buildErrorView(BuildContext context, CourseListState courseList) {
    final errorText = sanitizeErrorMessage(courseList.error ?? 'Unknown error');
    final isTimeout = errorText.toLowerCase().contains('timeout');
    final isOffline = ref.watch(isOfflineProvider);
    final isNetworkError = isTransientNetworkError(courseList.error ?? '');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.cloud_off_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                isOffline
                    ? 'You\'re offline'
                    : isNetworkError
                        ? 'Connection problem'
                        : 'Could not load courses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  isOffline
                      ? 'Connect to the internet and tap retry to load fresh data.'
                      : isNetworkError
                          ? 'We couldn\'t reach the server. Check your connection and tap retry.'
                          : isTimeout
                              ? 'The request took too long. Please check your connection and try again.'
                              : 'Something went wrong. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              // Show the raw error in tiny text so we can diagnose issues
              // without leaving the app.
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  errorText,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isRetrying ? null : () => _handleRetry(),
                icon: _isRetrying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isRetrying ? 'Retrying…' : 'Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Retry the failed fetch with exponential backoff. This handles the
  /// common case where the device just came back online but the OS hasn't
  /// finished setting up the network stack — the first DNS lookup fails
  /// with `Failed host lookup`, but the second or third one succeeds.
  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      // Invalidate enrolled IDs so the whole pipeline re-fetches fresh data.
      ref.invalidate(enrolledCourseIdsProvider);
      final notifier = ref.read(
        courseListProvider(widget.enrolledOnly).notifier,
      );
      await retryTransient(
        () => notifier.loadInitial(forceRefresh: true),
        maxAttempts: 3,
        initialDelay: const Duration(seconds: 1),
      );
    } catch (_) {
      // loadInitial already sets state.error; the UI will show it.
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  Widget _buildOfflineMessage(
    BuildContext context, {
    required String title,
    required String message,
    required bool showSpinner,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(),
                )
              else
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
