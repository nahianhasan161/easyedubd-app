import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';

/// Resolves the avatar URL to display for a profile.
///
/// Priority:
///   1. The `avatar_url` stored in the `profiles` table.
///   2. The auth provider's picture (e.g. Google account photo) — this is the
///      image that is effectively used when the profile column is empty.
///   3. `null` when neither is available (callers fall back to initials).
String? resolveAvatarUrl(Profile? profile) {
  final fromProfile = profile?.avatarUrl;
  if (fromProfile != null && fromProfile.trim().isNotEmpty) {
    return fromProfile.trim();
  }

  final user = Supabase.instance.client.auth.currentUser;
  final metadata = user?.userMetadata;
  if (metadata != null) {
    final candidate = metadata['avatar_url'] ?? metadata['picture'];
    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
  }

  return null;
}
