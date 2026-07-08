import 'package:easyedubd_app/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authListenable = Provider<Listenable>((ref) {
  final controller = ChangeNotifier();

  ref.listen(authStateProvider, (previous, next) {
    final event = next.value?.event;

    // Only redirect-relevant events should trigger a router refresh.
    // tokenRefreshed, userUpdated, etc. should NOT cause a rebuild.
    if (event == AuthChangeEvent.signedOut) {
      controller.notifyListeners();
    }
    /* if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.signedOut ||
        event == AuthChangeEvent.initialSession) {
      controller.notifyListeners();
    } */
  });

  return controller;
});
