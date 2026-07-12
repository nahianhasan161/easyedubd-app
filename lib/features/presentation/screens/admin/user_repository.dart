import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_device.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaginatedUsers {
  final List<Profile> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedUsers({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => (total / pageSize).ceil();
  int get start => total == 0 ? 0 : (page - 1) * pageSize + 1;
  int get end => (start + items.length - 1).clamp(0, total);
}

class UserRepository {
  final SupabaseClient _supabase;

  UserRepository(this._supabase);

  Future<PaginatedUsers> getUsers({
    required int page,
    int pageSize = 15,
  }) async {
    final start = (page - 1) * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false)
        .range(start, end)
        .count(CountOption.exact);

    final data = response.data as List;
    final items = data
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaginatedUsers(
      items: items,
      total: response.count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> updateRole(String id, String role) async {
    await _supabase.from('profiles').update({'role': role}).eq('id', id);
  }

  Future<List<UserDevice>> getUserDevices(String userId) async {
    final data = await _supabase
        .from('user_devices')
        .select()
        .eq('user_id', userId)
        .order('last_seen_at', ascending: false);

    return (data as List)
        .map((e) => UserDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setDeviceApproved({
    required String deviceId,
    required bool approved,
    required String adminId,
    DateTime? revokedAt,
  }) async {
    await _supabase.from('user_devices').update({
      'approved': approved,
      'approved_at': approved ? DateTime.now().toIso8601String() : null,
      'approved_by': approved ? adminId : null,
      'revoked_at': approved ? null : revokedAt?.toIso8601String(),
    }).eq('id', deviceId);
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(supabaseProvider));
});
