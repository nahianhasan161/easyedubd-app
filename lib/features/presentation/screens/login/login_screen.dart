import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:easyedubd_app/core/providers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    String getErrorMessage(Object error) {
      final text = error.toString();

      final match = RegExp(r'message:\s([^,)]+)').firstMatch(text);

      if (match != null) {
        return match.group(1)!.trim();
      }

      return "Something went wrong";
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// ERROR DISPLAY
            if (authState.hasError)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Login Failed",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getErrorMessage(authState.error!),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),

            const SizedBox(height: 10),

            /// EMAIL FIELD
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            /// PASSWORD FIELD
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// LOGIN BUTTON (EMAIL/PASSWORD)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(authControllerProvider.notifier)
                      .signInWithEmail(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );
                },
                child: const Text("Login"),
              ),
            ),

            const SizedBox(height: 10),

            /// GOOGLE LOGIN
            /*   ElevatedButton.icon(
              onPressed: () {
                ref.read(authControllerProvider.notifier).signInWithGoogle();
              },
              icon: Icon(Icons.abc),
              label: const Text("Sign in with Google"),
            ), */
            const SizedBox(height: 10),

            /// DASHBOARD
            /* ElevatedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.dashboard),
              label: const Text("Dashboard"),
            ),

            const SizedBox(height: 10), */

            /// LOGOUT
            /* ElevatedButton.icon(
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            ), */
          ],
        ),
      ),
    );
  }
}
