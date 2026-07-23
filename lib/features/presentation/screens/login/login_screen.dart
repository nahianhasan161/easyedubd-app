import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/core/providers/auth_notifier.dart';
import 'package:easyedubd_app/core/startup/startup_controller.dart';
import 'package:easyedubd_app/core/startup/startup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Authentication Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Maps a raw auth/network error into a clear, user-friendly message.
  String _friendlyError(Object? error) {
    final text = (error?.toString() ?? '').toLowerCase();

    if (text.contains('invalid login') ||
        text.contains('invalid credentials') ||
        text.contains('email or password') ||
        text.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (text.contains('user not found') || text.contains('no user')) {
      return 'No account found with this email. Please check the address.';
    }
    if (text.contains('email not confirmed') ||
        text.contains('not confirmed')) {
      return 'Please confirm your email address before signing in.';
    }
    if (text.contains('too many requests') ||
        text.contains('rate limit') ||
        text.contains('captcha')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (text.contains('network') ||
        text.contains('socket') ||
        text.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (text.contains('weak password')) {
      return 'Your password is too weak.';
    }
    return 'We could not sign you in. Please try again.';
  }

  Future<void> _signIn() async {
    // Clear any previous error before validating.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.hasError) {
      setState(() => _errorMessage = _friendlyError(authState.error));
      return;
    }

    // Re-run the startup check (device approval) for the new session, then
    // route explicitly so the first login always navigates.
    final status = await ref.read(startupProvider.notifier).initialize();

    if (!mounted) return;

    switch (status) {
      case AppStartupState.authenticated:
        context.go('/dashboard');
      case AppStartupState.pendingDevice:
        context.go('/device-pending');
      case AppStartupState.blockedDevice:
        context.go('/device-blocked');
      case AppStartupState.profileIncomplete:
        context.go('/profile-onboarding');
      case AppStartupState.unauthenticated:
      case AppStartupState.loading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Offline warning
                    if (isOffline)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No internet connection. Please check your network.',
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isOffline) const SizedBox(height: 16),

                    // App logo
                    Image.asset(
                      'assets/icons/eeb-logo.png', //assets/icons/logo.png
                      height: 120,
                      width: 120,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Easy Education Bangladesh',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Error banner
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: isLoading || isOffline ? null : (_) => _signIn(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Login button / loading
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (isLoading || isOffline)
                            ? null
                            : _signIn,
                        child: isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Signing in...'),
                                ],
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google sign-in
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: (isLoading || isOffline)
                            ? null
                            : () async {
                                setState(() => _errorMessage = null);
                                // Trigger Sign-in
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithGoogle();
                                if (!mounted) return;
                                final gState = ref.read(authControllerProvider);
                                // Log error to PostHog if it occurs
                                if (gState.hasError) {
                                  await Posthog().capture(
                                    eventName: 'google_signin_error',
                                    properties: {
                                      'error_message': gState.error.toString(),
                                      'timestamp': DateTime.now()
                                          .toIso8601String(),
                                    },
                                  );
                                  // Show raw error in the dialog for debugging
                                  await _showErrorDialog(
                                    "Google Sign-In Failed: ${gState.error.toString()}",
                                  );
                                  setState(
                                    () => _errorMessage = _friendlyError(
                                      gState.error,
                                    ),
                                  );
                                  return;
                                }
                                // Success: Proceed to initialization
                                final status = await ref
                                    .read(startupProvider.notifier)
                                    .initialize();
                                if (!mounted) return;
                                switch (status) {
                                  case AppStartupState.authenticated:
                                    context.go('/dashboard');
                                  case AppStartupState.pendingDevice:
                                    context.go('/device-pending');
                                  case AppStartupState.blockedDevice:
                                    context.go('/device-blocked');
                                  case AppStartupState.profileIncomplete:
                                    context.go('/profile-onboarding');
                                  case AppStartupState.unauthenticated:
                                  case AppStartupState.loading:
                                    break;
                                }
                              },
                        icon: const Icon(Icons.g_mobiledata_rounded),
                        label: Text(isLoading ? 'Signing in...' : 'Continue with Google'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
