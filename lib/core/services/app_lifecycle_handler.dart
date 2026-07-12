import 'package:easyedubd_app/core/startup/startup_controller.dart';
import 'package:easyedubd_app/core/startup/startup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyedubd_app/core/router/app_router.dart';

class AppLifecycleHandler extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleHandler({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleHandler> createState() =>
      _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends ConsumerState<AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint("LIFECYCLE: $state");
    if (state != AppLifecycleState.resumed) return;
    debugPrint("RESUMED");
    final result = await ref.read(startupProvider.notifier).recheckOnResume();
    debugPrint("INITIALIZE RESULT: $result");
    if (!mounted) return;
    final router = ref.read(appRouterProvider);
    switch (result) {
      case AppStartupState.authenticated:
        // User is still allowed
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
