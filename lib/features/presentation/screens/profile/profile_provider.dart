import 'package:easyedubd_app/core/providers/auth_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_repository.dart';

/// The signed-in user's id, exposed as a provider so it can be overridden in tests.
/// Depends on [authStateProvider] so it re-keys when the account changes.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser?.id;
});

/// Loads the signed-in user's profile.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) return null;

  final repository = ref.read(profileRepositoryProvider);
  return repository.getProfile(id);
});

/// True when the signed-in user's profile role is 'admin'.
final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentProfileProvider);
  return profile.value?.role?.toLowerCase() == 'admin';
});

/// True when the signed-in user's profile has all required onboarding fields.
final profileCompleteProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentProfileProvider).value;
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
});

class ProfileController extends AsyncNotifier<Profile?> {
  late final ProfileRepository _repository;

  @override
  Future<Profile?> build() async {
    _repository = ref.read(profileRepositoryProvider);
    final id = ref.watch(currentUserIdProvider);
    if (id == null) return null;
    return _repository.getProfile(id);
  }

  Future<void> save(Profile profile) async {
    state = const AsyncLoading();
    try {
      final saved = await _repository.upsertProfile(profile);
      state = AsyncData(saved);
      ref.invalidate(currentProfileProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(
  ProfileController.new,
);
