import 'package:easyedubd_app/core/providers/auth_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
      data: (session) {
        if (session != null) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
