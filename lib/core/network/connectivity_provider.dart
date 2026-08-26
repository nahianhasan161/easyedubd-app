import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the current connectivity result list whenever it changes.
/// On first read, fetches the current state so the app doesn't sit in an
/// indeterminate "offline" state until the first stream event.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) async* {
  // Emit the current state first so consumers don't default to offline
  // while waiting for the first change event.
  final current = await Connectivity().checkConnectivity();
  yield current;
  yield* Connectivity().onConnectivityChanged;
});

/// True when the device appears to have no usable internet connectivity.
/// Defaults to `false` (assume online) until the connectivity stream has
/// emitted at least once.
final isOfflineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  final value = connectivity.value;
  if (value == null) return false;
  return value.every((result) => result == ConnectivityResult.none);
});
