import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint("LIFECYCLE: $state");
    if (state != AppLifecycleState.resumed) return;
    debugPrint("RESUMED");
    // Some Android OEMs reset the secure flag once the app is backgrounded,
    // so re-apply screenshot / data-leakage protection on every resume.
    await ScreenSecurityService.reapply();
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
    final isOffline = ref.watch(isOfflineProvider);

    return Stack(
      children: [
        widget.child,
        if (isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
