import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/shared/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Column(
        children: [
          if (ref.watch(isOffline)) const OfflineBanner(),
          Expanded(
            child: const Center(
              child: Text('No notifications yet.'),
            ),
          ),
        ],
      ),
    );
  }
}
