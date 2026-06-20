import 'package:easyedubd_app/core/providers/auth_notifier.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: authState.when(
          data: (session) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(session?.user.id ?? "Not Signed In"),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle();
                  },
                  icon: const Icon(Icons.login),
                  label: const Text("Sign in with Google"),
                ),

                ElevatedButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.dashboard),
                  label: const Text("Dashboard"),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text("Error: $e"),
        ),
      ),
    );
  }
}
