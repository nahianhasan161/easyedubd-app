import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easyedubd_app/core/device/device_provider.dart';
import 'package:easyedubd_app/core/device/device_repository.dart';
import 'package:easyedubd_app/core/network/connectivity_provider.dart';
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

    // If we're offline, trust the cached/local session and skip the network
    // checks that would otherwise timeout and incorrectly bounce the user
    // back to the device-pending / login screens.
    final isOffline = _isOffline();

    final deviceService = ref.read(deviceServiceProvider);
    final deviceInfo = await deviceService.getDeviceInfo().timeout(
      _deviceInfoTimeout,
      onTimeout: () => throw TimeoutException('device info timeout'),
    );

    final deviceRepository = ref.read(deviceRepositoryProvider);

    if (isOffline) {
      // Cannot verify the device right now, but a valid session is present
      // and the device was previously approved (otherwise we wouldn't have
      // a session in the first place). Stay authenticated so the user can
      // browse from the local cache.
      //
      // We also skip the profile check: a user who was previously
      // authenticated has necessarily passed profile-onboarding, and
      // re-running it offline would falsely bounce them to the onboarding
      // screen if the profile query times out.
      return AppStartupState.authenticated;
    }

    DeviceVerificationResult deviceResult;
    try {
      deviceResult = await deviceRepository
          .verifyCurrentDevice(deviceInfo)
          .timeout(_verifyDeviceTimeout);
    } on TimeoutException {
      // Don't know if the device is still approved. Keep the user signed in
      // (they have a valid session) and let them browse from the cache.
      return AppStartupState.authenticated;
    } catch (e) {
      // Network error reaching Supabase - treat like offline: keep the user
      // signed in so they can keep reading cached content.
      if (_isNetworkError(e)) {
        return AppStartupState.authenticated;
      }
      // Genuine server-side rejection (e.g. device revoked). Surface it.
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

    return _checkProfileOrAuthenticated(session, deviceInfo);
  }

  /// Fallback profile check used when device verification succeeds.
  /// Treats any failure to fetch the profile as "incomplete" unless the
  /// device is offline, in which case we trust the existing session.
  Future<AppStartupState> _checkProfileOrAuthenticated(
    Session session,
    dynamic deviceInfo,
  ) async {
    if (_isOffline()) {
      return AppStartupState.authenticated;
    }

    final profileRepository = ref.read(profileRepositoryProvider);
    Profile? profile;
    try {
      profile = await profileRepository
          .getProfile(session.user.id)
          .timeout(_profileTimeout, onTimeout: () => null);
    } catch (e) {
      if (_isNetworkError(e)) {
        return AppStartupState.authenticated;
      }
      profile = null;
    }

    final complete = _isProfileComplete(profile);
    if (!complete) {
      return AppStartupState.profileIncomplete;
    }

    return AppStartupState.authenticated;
  }

  bool _isOffline() {
    final connectivity = ref.read(connectivityProvider);
    final results = connectivity.value;
    if (results == null) return false; // unknown → don't assume offline
    return results.every((r) => r == ConnectivityResult.none);
  }

  bool _isNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socket') ||
        s.contains('network') ||
        s.contains('connection') ||
        s.contains('timeout') ||
        s.contains('failed host lookup') ||
        s.contains('no address') ||
        s.contains('clientexception');
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
