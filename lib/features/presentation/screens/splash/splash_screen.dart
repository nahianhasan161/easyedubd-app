import 'package:easyedubd_app/core/startup/startup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(startupProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(startupProvider);

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
