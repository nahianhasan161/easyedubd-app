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
/// It reacts to every auth event (not just when the stream value changes),
/// comparing the actual signed-in user id before and after, so it also catches
/// account switches that don't emit a new signedOut/signedIn event.
final authResetProvider = Provider<void>((ref) {
  String? userIdOf(AsyncValue<AuthState>? state) =>
      state?.value?.session?.user.id;

  ref.listen(authStateProvider, (previous, next) {
    final prevUser = userIdOf(previous);
    final nextUser = userIdOf(next);

    // Invalidate when the user identity changes. Also invalidate when the
    // stream emits but we can't tell (e.g. account switch without a clear
    // event) by comparing the live current user id as a fallback.
    final liveUser = Supabase.instance.client.auth.currentUser?.id;
    if (prevUser != nextUser || (prevUser != liveUser && nextUser != liveUser)) {
      ref.invalidate(currentProfileProvider);
      ref.invalidate(enrolledCourseIdsProvider);
      ref.invalidate(startupProvider);
    }
  });
});
