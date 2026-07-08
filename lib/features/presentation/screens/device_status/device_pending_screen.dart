import 'package:easyedubd_app/core/providers/auth_notifier.dart';
import 'package:easyedubd_app/core/startup/startup_controller.dart';
import 'package:easyedubd_app/core/startup/startup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DevicePendingScreen extends ConsumerWidget {
  const DevicePendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 90,
                  color: Colors.orange,
                ),

                const SizedBox(height: 24),

                const Text(
                  "Device Approval Pending",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                const Text(
                  "Your device has been registered successfully.\n\n"
                  "Please wait until an administrator approves this device.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 40),
                // TODO: Not Redirecting to dashboard after approval. Need to check if the device is approved or not and then redirect to dashboard.
                FilledButton.icon(
                  onPressed: () async {
                    final result = await ref
                        .read(startupProvider.notifier)
                        .initialize();

                    debugPrint("Check Again result: $result");

                    if (!context.mounted) return;

                    switch (result) {
                      case AppStartupState.authenticated:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Device approved! Redirecting...'),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        if (!context.mounted) return;

                        context.go('/dashboard');
                        break;

                      case AppStartupState.pendingDevice:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '⏳ Your device is still waiting for approval.',
                            ),
                          ),
                        );
                        break;

                      case AppStartupState.blockedDevice:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🚫 Your device has been blocked.'),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        if (!context.mounted) return;

                        context.go('/device-blocked');
                        break;

                      case AppStartupState.unauthenticated:
                        context.go('/');
                        break;

                      case AppStartupState.loading:
                        break;
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Check Again"),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
