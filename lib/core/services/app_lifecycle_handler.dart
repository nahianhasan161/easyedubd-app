import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easyedubd_app/core/cache/realtime_cache_invalidator.dart';
import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/core/services/screen_security_service.dart';
import 'package:easyedubd_app/core/startup/startup_controller.dart';
import 'package:easyedubd_app/core/startup/startup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyedubd_app/core/router/app_router.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class AppLifecycleHandler extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleHandler({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleHandler> createState() =>
      _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends ConsumerState<AppLifecycleHandler>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<void>? _invalidationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      final isOffline = result.every((r) => r == ConnectivityResult.none);
      if (isOffline) {
        try {
          Posthog().disable();
        } catch (_) {}
      } else {
        try {
          Posthog().enable();
        } catch (_) {}
      }
    });

    // React to realtime cache invalidations by re-fetching from Supabase.
    _invalidationSubscription =
        RealtimeCacheInvalidator.invalidations.listen((_) {
      if (!mounted) return;
      _onCacheInvalidated();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _invalidationSubscription?.cancel();
    super.dispose();
  }

  void _onCacheInvalidated() {
    final isOffline = ref.read(isOfflineProvider);
    if (isOffline) return; // wait until we have connectivity to refresh
    ref.invalidate(enrolledCourseIdsProvider);
    ref.read(courseListProvider(false).notifier).loadInitial();
    ref.read(courseListProvider(true).notifier).loadInitial();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint("LIFECYCLE: $state");
    if (state != AppLifecycleState.resumed) return;
    debugPrint("RESUMED");
    // Some Android OEMs reset the secure flag once the app is backgrounded,
    // so re-apply screenshot / data-leakage protection on every resume.
    await ScreenSecurityService.reapply();

    // Kick the cache-version poller immediately on resume. It self-skips
    // when offline and is debounced internally, so this is safe.
    RealtimeCacheInvalidator.checkNow();

    // If we're offline, don't try to re-verify the device or refetch data -
    // the cache is still valid. Just stay on the current screen.
    final isOffline = ref.read(isOfflineProvider);
    if (isOffline) return;

    final result = await ref.read(startupProvider.notifier).recheckOnResume();
    debugPrint("INITIALIZE RESULT: $result");
    if (!mounted) return;
    final router = ref.read(appRouterProvider);
    switch (result) {
      case AppStartupState.profileIncomplete:
        if (router.state.uri.path != '/profile-onboarding') {
          router.go('/profile-onboarding');
        }
        break;

      case AppStartupState.authenticated:
        // Refresh course & enrollment data so that courses/enrollments
        // created while the app was backgrounded show up without a full
        // restart (previously only "Clear Data" fixed the stale data).
        _refreshCourseData();
        break;

      case AppStartupState.pendingDevice:
        if (router.state.uri.path != '/device-pending') {
          router.go('/device-pending');
        }

        break;

      case AppStartupState.blockedDevice:
        router.go('/device-blocked');

        break;

      case AppStartupState.unauthenticated:
        router.go('/');
        break;

      case AppStartupState.loading:
        break;
    }
  }

  void _refreshCourseData() {
    // Drop the cached enrollment set so it is re-fetched.
    ref.invalidate(enrolledCourseIdsProvider);
    // Re-fetch both course lists (All Courses + My Courses) so newly
    // added courses appear without restarting the app.
    ref.read(courseListProvider(false).notifier).loadInitial();
    ref.read(courseListProvider(true).notifier).loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    // The offline banner is rendered inside each screen (e.g. below the
    // filter row / below the AppBar in CourseListScreen) rather than as a
    // global overlay here, so it can be placed contextually and so it does
    // not affect the bottom navigation bar's layout.
    return widget.child;
  }
}
