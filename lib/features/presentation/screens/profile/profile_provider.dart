import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_repository.dart';

/// The signed-in user's id, exposed as a provider so it can be overridden in tests.
final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

/// Loads the signed-in user's profile.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) return null;

  final repository = ref.read(profileRepositoryProvider);
  return repository.getProfile(id);
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
