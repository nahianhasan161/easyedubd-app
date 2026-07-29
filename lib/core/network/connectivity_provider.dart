import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> _checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('example.com')
        .timeout(const Duration(seconds: 5));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOfflineProvider = StreamProvider<bool>((ref) async* {
  final hasInternet = await _checkInternetConnection();
  yield !hasInternet;

  await for (final connectivity in Connectivity().onConnectivityChanged) {
    if (connectivity.contains(ConnectivityResult.none)) {
      yield true;
    } else {
      final hasInternet = await _checkInternetConnection();
      yield !hasInternet;
    }
  }
});

final isOffline = Provider<bool>((ref) {
  final connectivity = ref.watch(isOfflineProvider);
  // Default to false (assume online) until the stream confirms offline.
  // This prevents a false-offline assumption on cold start before the
  // connectivity stream has emitted its first value.
  return connectivity.value ?? false;
});