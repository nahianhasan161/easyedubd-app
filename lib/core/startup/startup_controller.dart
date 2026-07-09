import 'package:easyedubd_app/core/device/device_provider.dart';
import 'package:easyedubd_app/core/device/device_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';

enum AppStartupState {
  loading,
  unauthenticated,
  authenticated,
  pendingDevice,
  blockedDevice,
}

class StartupController extends AsyncNotifier<AppStartupState> {
  late final SupabaseClient supabase;

  @override
  Future<AppStartupState> build() async {
    supabase = ref.read(supabaseProvider);
    return initialize();
  }

  Future<AppStartupState> initialize() async {
  state = const AsyncLoading();

  try {
    final result = await _performStartupCheck();

    state = AsyncData(result);

    return result;
  } catch (e, st) {
    state = AsyncError(e, st);
    return AppStartupState.unauthenticated;
  }
}
Future<AppStartupState> recheckOnResume() async {
  try {
    // IMPORTANT: Do NOT set AsyncLoading() here.
    final result = await _performStartupCheck();

    // Only notify if the state actually changed.
    if (state.value != result) {
      state = AsyncData(result);
    }

    return result;
  } catch (e, st) {
    state = AsyncError(e, st);
    return AppStartupState.unauthenticated;
  }
}
  Future<void> refresh() async {
    await initialize();
  }

  void setState(AppStartupState value) {
    state = AsyncData(value);
  }

  Future<AppStartupState> _performStartupCheck() async {
  final session = supabase.auth.currentSession;

  if (session == null) {
    return AppStartupState.unauthenticated;
  }

  final deviceService = ref.read(deviceServiceProvider);
  final deviceInfo = await deviceService.getDeviceInfo();

  final deviceRepository = ref.read(deviceRepositoryProvider);
  final result = await deviceRepository.verifyCurrentDevice(deviceInfo);

  switch (result.status) {
    case DeviceVerificationStatus.approved:
      return AppStartupState.authenticated;

    case DeviceVerificationStatus.pending:
      return AppStartupState.pendingDevice;

    case DeviceVerificationStatus.revoked:
      return AppStartupState.blockedDevice;
  }
}
}
