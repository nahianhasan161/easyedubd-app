import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the current connectivity result list whenever it changes.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// True when the device appears to have no usable internet connectivity.
final isOfflineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.value?.every(
            (result) => result == ConnectivityResult.none,
          ) ??
          true;
});
