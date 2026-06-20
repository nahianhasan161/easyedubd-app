import 'dart:async';

import 'package:easyedubd_app/features/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _userId;
  final supabase = Supabase.instance.client;
  @override
  void initState() {
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _userId = data.session?.user.id;
      });
    });
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          children: [
            Text(_userId ?? 'Not Signed In'),
            ElevatedButton.icon(
              onPressed: () async {
                // Navigate to the DashboardPage
                /// TODO: update the Web client ID with your own.
                ///
                /// Web Client ID that you registered with Google Cloud.
                final webClientId = dotenv.env['WEBCLIENTID'];

                /// TODO: update the iOS client ID with your own.
                ///
                /// iOS Client ID that you registered with Google Cloud.
                final iosClientId = dotenv.env['IOSCLIENTID'];

                // Google sign in on Android will work without providing the Android
                // Client ID registered on Google Cloud.

                final GoogleSignIn signIn = GoogleSignIn.instance;

                // At the start of your app, initialize the GoogleSignIn instance
                unawaited(
                  signIn.initialize(
                    clientId: iosClientId,
                    serverClientId: webClientId,
                  ),
                );

                // Perform the sign in
                final googleAccount = await signIn.authenticate();
                final googleAuthorization = await googleAccount
                    .authorizationClient
                    .authorizationForScopes([
                      'https://www.googleapis.com/auth/userinfo.email',
                    ]);
                final googleAuthentication = googleAccount.authentication;
                final idToken = googleAuthentication.idToken;
                final accessToken = googleAuthorization!.accessToken;

                if (idToken == null) {
                  throw 'No ID Token found.';
                }

                await supabase.auth.signInWithIdToken(
                  provider: OAuthProvider.google,
                  idToken: idToken,
                  accessToken: accessToken,
                );
              },

              icon: const Icon(Icons.login),
              label: const Text("Sign in With Google"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                context.push('/dashboard');
              },

              icon: const Icon(Icons.dashboard),

              label: const Text('Dashboard'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final GoogleSignIn signIn = GoogleSignIn.instance;

                // Sign out from Google
                //await GoogleSignIn.instance.disconnect();
                await signIn.signOut();

                // Sign out from Supabase

                await supabase.auth.signOut();
              },

              icon: const Icon(Icons.logout),

              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
