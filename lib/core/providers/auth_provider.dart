import 'package:easyedubd_app/core/startup/startup_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (data) => data.session,
    loading: () => null,
    error: (_, _) => null,
  );
});

/// Resets all user-scoped state whenever the auth session changes
/// (sign-in, sign-out, or switching accounts). Without this, providers like
/// the profile cache and enrolled-course ids keep the previous user's data.
///
/// It only invalidates `startupProvider` on **identity transitions**
/// (null → user, user → null, or user A → user B), NOT on every
/// `onAuthStateChange` emit. The Supabase auth stream emits on every
/// token refresh, and re-running the full startup check on every refresh
/// would cause an infinite loading loop on the splash screen.
final authResetProvider = Provider<void>((ref) {
  String? userIdOf(AsyncValue<AuthState>? state) =>
      state?.value?.session?.user.id;

  ref.listen(authStateProvider, (previous, next) {
    final prevUser = userIdOf(previous);
    final nextUser = userIdOf(next);

    // Only act on identity transitions, not on token refreshes where the
    // user id stays the same. A token refresh fires `onAuthStateChange`
    // with the same user id before and after — we must NOT invalidate the
    // startup provider in that case, or the splash screen will loop.
    if (prevUser == nextUser) return;

    ref.invalidate(currentProfileProvider);
    ref.invalidate(enrolledCourseIdsProvider);
    // Don't invalidate startupProvider here. The router redirect logic
    // reads startupState and will re-run the startup check if needed.
    // Invalidating it from this listener creates a loop because the
    // startup check itself can trigger auth state changes.
  });
});
