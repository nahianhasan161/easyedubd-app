import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, Session?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<Session?> {
  late final SupabaseClient supabase;

  @override
  Future<Session?> build() async {
    supabase = ref.read(supabaseProvider);
    return supabase.auth.currentSession;
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      state = AsyncData(response.session);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();

    try {
      final webClientId = dotenv.env['WEBCLIENTID'];
      final iosClientId = dotenv.env['IOSCLIENTID'];

      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.authenticate();
      final auth = googleUser.authentication;

      final idToken = auth.idToken;

      if (idToken == null) {
        throw Exception("Missing ID token");
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      state = AsyncData(response.session);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    await GoogleSignIn.instance.signOut();
    await supabase.auth.signOut();

    state = const AsyncData(null);
  }
}
