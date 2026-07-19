import 'package:easyedubd_app/features/presentation/screens/admin/user_device.dart';
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

/// Loads one page of a user's registered devices.
final userDevicesProvider = FutureProvider.family<PaginatedDevices,
    DevicesQuery>((ref, query) {
  return ref
      .read(userRepositoryProvider)
      .getUserDevices(query.userId, page: query.page);
});
