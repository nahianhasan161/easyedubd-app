import 'dart:async';

import 'package:easyedubd_app/core/device/device_provider.dart';
import 'package:easyedubd_app/core/storage/hive_init.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/providers/course_list_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_provider.dart';
import '../providers/auth_provider.dart';

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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Login timed out. Please check your connection.'),
      );

      state = AsyncData(response.session);
      await setLocalAuth();
      ref.invalidate(localAuthProvider);
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
      await setLocalAuth();
      ref.invalidate(localAuthProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    await GoogleSignIn.instance.signOut();
    await supabase.auth.signOut();
    await clearLocalAuth();
    await HiveInit.clearAll();
    ref.invalidate(localAuthProvider);
    ref.invalidate(currentProfileProvider);
    ref.invalidate(enrolledCourseIdsProvider);
    ref.invalidate(courseListProvider(false));
    ref.invalidate(courseListProvider(true));

    state = const AsyncData(null);
  }

  Future<void> refreshSession() async {
    try {
      final response = await supabase.auth.refreshSession();
      state = AsyncData(response.session);
    } catch (e, st) {
      debugPrint("========== SESSION REFRESH ERROR ==========");
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);
      state = AsyncError(e, st);
    }
  }
}
