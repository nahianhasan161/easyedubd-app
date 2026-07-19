import 'package:easyedubd_app/features/presentation/screens/admin/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a specific page of the user list, including any active
/// search text and role filter. Used as the family key so the provider
/// recomputes when filters or the page change.
class UsersQuery {
  const UsersQuery({
    required this.page,
    this.search,
    this.role,
  });

  final int page;
  final String? search;
  final String? role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsersQuery &&
          other.page == page &&
          other.search == search &&
          other.role == role;

  @override
  int get hashCode => Object.hash(page, search, role);
}

/// Loads one filtered/searched page of registered users.
final usersProvider =
    FutureProvider.family<PaginatedUsers, UsersQuery>((ref, query) {
  final repository = ref.read(userRepositoryProvider);
  return repository.getUsers(
    page: query.page,
    search: query.search,
    role: query.role,
  );
});
