
import 'package:easyedubd_app/core/providers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceBlockedScreen extends ConsumerWidget {
  const DeviceBlockedScreen({super.key});

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
                  Icons.block_rounded,
                  size: 90,
                  color: Colors.red,
                ),

                const SizedBox(height: 24),

                const Text(
                  "Device Blocked",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "This device is no longer authorized to access this account.\n\n"
                  "Please contact Easy Education BD support if you think this is a mistake.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 40),

                FilledButton.icon(
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