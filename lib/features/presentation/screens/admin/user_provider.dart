import 'package:easyedubd_app/features/presentation/screens/admin/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads one page of registered users. `page` is 1-based.
final usersProvider =
    FutureProvider.family<PaginatedUsers, int>((ref, page) {
  final repository = ref.read(userRepositoryProvider);
  return repository.getUsers(page: page);
});
