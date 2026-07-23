import 'dart:async';

import 'package:easyedubd_app/core/device/device_provider.dart';
import 'package:easyedubd_app/core/device/device_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';

enum AppStartupState {
  loading,
  unauthenticated,
  authenticated,
  pendingDevice,
  blockedDevice,
  profileIncomplete,
}

class StartupController extends AsyncNotifier<AppStartupState> {
  late final SupabaseClient supabase;

  static const _deviceInfoTimeout = Duration(seconds: 4);
  static const _verifyDeviceTimeout = Duration(seconds: 4);
  static const _profileTimeout = Duration(seconds: 5);

  @override
  Future<AppStartupState> build() async {
    supabase = ref.read(supabaseProvider);
    return initialize();
  }

  Future<AppStartupState> initialize() async {
    state = const AsyncLoading();

    try {
      final result = await _performStartupCheck().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Startup timed out after 15 seconds'),
      );

      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return AppStartupState.unauthenticated;
    }
  }

  Future<AppStartupState> recheckOnResume() async {
    try {
      final result = await _performStartupCheck().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Resume check timed out after 15 seconds'),
      );

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
    final deviceInfo = await deviceService.getDeviceInfo().timeout(
      _deviceInfoTimeout,
      onTimeout: () => throw TimeoutException('device info timeout'),
    );

    final deviceRepository = ref.read(deviceRepositoryProvider);
    DeviceVerificationResult deviceResult;
    try {
      deviceResult = await deviceRepository
          .verifyCurrentDevice(deviceInfo)
          .timeout(_verifyDeviceTimeout);
    } on TimeoutException {
      return AppStartupState.pendingDevice;
    }

    switch (deviceResult.status) {
      case DeviceVerificationStatus.revoked:
        return AppStartupState.blockedDevice;
      case DeviceVerificationStatus.pending:
        return AppStartupState.pendingDevice;
      case DeviceVerificationStatus.approved:
        break;
    }

    final profileRepository = ref.read(profileRepositoryProvider);
    Profile? profile;
    try {
      profile = await profileRepository
          .getProfile(session.user.id)
          .timeout(_profileTimeout, onTimeout: () => null);
    } catch (_) {
      profile = null;
    }

    final complete = _isProfileComplete(profile);
    if (!complete) {
      return AppStartupState.profileIncomplete;
    }

    return AppStartupState.authenticated;
  }

  bool _isProfileComplete(Profile? profile) {
    if (profile == null) return false;

    final fields = [
      profile.fullName,
      profile.phone,
      profile.currentLevel,
      profile.institute,
      profile.department,
      profile.session,
      profile.currentYear,
      profile.gender,
    ];

    return fields.every((field) => field != null && field.trim().isNotEmpty);
  }
}
