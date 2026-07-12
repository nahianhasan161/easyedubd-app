import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<Profile?> getProfile(String id) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;

    return Profile.fromJson(data);
  }

  Future<Profile> upsertProfile(Profile profile) async {
    final data = await _supabase
        .from('profiles')
        .upsert(profile.toUpsertJson(), onConflict: 'id')
        .select()
        .single();

    return Profile.fromJson(data);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(supabaseProvider));
});
