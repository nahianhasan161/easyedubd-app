import 'package:easyedubd_app/core/device/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
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
      final installationId = await ref
          .read(deviceServiceProvider)
          .getInstallationId();
      debugPrint("Installation ID: $installationId");
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final deviceInfo = await ref.read(deviceServiceProvider).getDeviceInfo();

    

      final verification = await ref
          .read(deviceRepositoryProvider)
          .verifyCurrentDevice(deviceInfo);

      print("Device status: ${verification.status}");
      print(verification.status);

      state = AsyncData(response.session);
    } catch (e, st) {
      debugPrint("========== LOGIN ERROR ==========");

      debugPrint(e.toString());

      debugPrintStack(stackTrace: st);

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
      final installationId = await ref
          .read(deviceServiceProvider)
          .getInstallationId();

      debugPrint("Installation ID: $installationId");

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
