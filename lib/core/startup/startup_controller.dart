import 'package:easyedubd_app/core/device/device_provider.dart';
import 'package:easyedubd_app/core/device/device_repository.dart';
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
    try {
      state = const AsyncLoading();

      final session = supabase.auth.currentSession;

      // User not logged in
      if (session == null) {
        state = const AsyncData(AppStartupState.unauthenticated);
        return AppStartupState.unauthenticated;
      }

      // Get current device information
      final deviceService = ref.read(deviceServiceProvider);
      final deviceInfo = await deviceService.getDeviceInfo();
      print(deviceInfo.toJson()); // 👈
      // Verify device with Supabase
      final deviceRepository = ref.read(deviceRepositoryProvider);
      final result = await deviceRepository.verifyCurrentDevice(deviceInfo);

      switch (result.status) {
        case DeviceVerificationStatus.approved:
          state = const AsyncData(AppStartupState.authenticated);
          return AppStartupState.authenticated;

        case DeviceVerificationStatus.pending:
          state = const AsyncData(AppStartupState.pendingDevice);
          return AppStartupState.pendingDevice;

        case DeviceVerificationStatus.revoked:
          state = const AsyncData(AppStartupState.blockedDevice);
          return AppStartupState.blockedDevice;
      }
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
}
