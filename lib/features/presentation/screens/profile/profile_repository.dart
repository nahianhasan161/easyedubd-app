import 'dart:async';
import 'dart:io';

import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:easyedubd_app/core/storage/local_cache_service.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase;
  final LocalCacheService _cache;

  ProfileRepository(this._supabase, [LocalCacheService? cache])
      : _cache = cache ?? LocalCacheService();

  Future<Profile?> getProfile(String id) async {
    final offline = !await _hasInternet();
    if (offline) {
      final cached = _cache.getCachedProfile();
      if (cached != null) return Profile.fromJson(cached);
      return null;
    }

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Profile fetch timeout'),
          );

      if (data != null) {
        final profile = Profile.fromJson(data);
        await _cache.cacheProfile(profile.toJson());
        return profile;
      }
    } catch (_) {
      // network failed, try cache
    }

    final cached = _cache.getCachedProfile();
    if (cached != null) return Profile.fromJson(cached);
    return null;
  }

  Future<Profile> upsertProfile(Profile profile) async {
    final data = await _supabase
        .from('profiles')
        .upsert(profile.toUpsertJson(), onConflict: 'id')
        .select()
        .single()
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Profile upsert timeout'),
        );

    final result = Profile.fromJson(data);
    await _cache.cacheProfile(result.toJson());
    return result;
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(supabaseProvider));
});
