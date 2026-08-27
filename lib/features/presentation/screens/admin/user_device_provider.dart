import 'package:easyedubd_app/features/presentation/screens/admin/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a specific page of a user's device list.
class DevicesQuery {
  const DevicesQuery({required this.userId, required this.page});

  final String userId;
  final int page;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevicesQuery &&
          other.userId == userId &&
          other.page == page;

  @override
  int get hashCode => Object.hash(userId, page);
}

/// Loads one page of a user's registered devices. Returns an empty
/// page on error so the provider never gets stuck in error state.
final userDevicesProvider = FutureProvider.family<PaginatedDevices,
    DevicesQuery>((ref, query) async {
  try {
    return await ref
        .read(userRepositoryProvider)
        .getUserDevices(query.userId, page: query.page);
  } catch (_) {
    return PaginatedDevices(items: const [], total: 0, page: 1, pageSize: 15);
  }
});
