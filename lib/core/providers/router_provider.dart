import 'package:easyedubd_app/core/providers/auth_provider.dart';
import 'package:easyedubd_app/core/startup/startup_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/onboarding/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A [ChangeNotifier] that exposes a public method to fire notifications.
class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

/// Drives GoRouter re-evaluation. The router itself is created ONCE; this
/// listenable is what triggers the redirect to run again when auth or the
/// startup pipeline changes state.
///
/// Recreating the GoRouter (by watching providers inside the router provider)
/// resets it to its initialLocation and remounts MaterialApp.router, which
/// causes a visible screen flash on cold start. So instead of rebuilding the
/// router, we notify this listenable and let the existing router re-run its
/// redirect.
final authListenable = Provider<Listenable>((ref) {
  final controller = _RouterRefreshNotifier();

  // Refresh on relevant auth transitions (sign-in / sign-out).
  ref.listen(authStateProvider, (previous, next) {
    final event = next.value?.event;
    if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.signedOut) {
      controller.refresh();
    }
  });

  // Refresh whenever the startup pipeline resolves (loading -> authenticated /
  // unauthenticated / pending / blocked). This is what moves the user off the
  // splash screen without recreating the router.
  ref.listen(startupProvider, (previous, next) {
    controller.refresh();
  });

  // Refresh when the onboarding flag resolves so a logged-out user moves off
  // the splash screen to onboarding/login without recreating the router.
  ref.listen(onboardingCompletedProvider, (previous, next) {
    controller.refresh();
  });

  ref.onDispose(controller.dispose);

  return controller;
});
