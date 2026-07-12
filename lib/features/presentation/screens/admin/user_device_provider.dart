import 'package:easyedubd_app/features/presentation/screens/admin/user_device.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the registered devices for a given user.
final userDevicesProvider =
    FutureProvider.family<List<UserDevice>, String>((ref, userId) {
  return ref.read(userRepositoryProvider).getUserDevices(userId);
});
