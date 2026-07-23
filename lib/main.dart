import 'dart:async';

import 'package:easyedubd_app/core/providers/auth_provider.dart';
import 'package:easyedubd_app/core/router/app_router.dart';
import 'package:easyedubd_app/core/services/app_lifecycle_handler.dart';
import 'package:easyedubd_app/core/services/screen_security_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final posthogFuture = Posthog().setup(
    PostHogConfig(
      'phc_nqsCr2zuWpeaysXty3k5txWDCNakM8obCumheGb7qKTD',
    )
      ..host = 'https://us.i.posthog.com'
      ..debug = true
      ..captureApplicationLifecycleEvents = true
      ..sessionReplay = true
      ..sessionReplayConfig.maskAllTexts = false
      ..sessionReplayConfig.maskAllImages = false
      ..sessionReplayConfig.throttleDelay = const Duration(milliseconds: 1000),
  ).timeout(
    const Duration(seconds: 5),
    onTimeout: () => Future<void>.value(),
  );

  final screenSecurityFuture = ScreenSecurityService.enable().timeout(
    const Duration(seconds: 5),
    onTimeout: () => Future<void>.value(),
  );

  final dotenvFuture = dotenv.load(fileName: ".env").timeout(
    const Duration(seconds: 5),
    onTimeout: () => Future<void>.value(),
  );

  await Future.wait([
    posthogFuture,
    screenSecurityFuture,
    dotenvFuture,
  ]);

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

  if (supabaseUrl != null && supabaseKey != null) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Supabase initialize timeout'),
    );
  }

  runApp(const ProviderScope(child: MyApp()));
}

final supabase = Supabase.instance.client;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authResetProvider);

    final router = ref.watch(appRouterProvider);

    return PostHogWidget(
      child: MaterialApp.router(
        title: 'Easy Education Bangladesh',
        routerConfig: router,
        debugShowCheckedModeBanner: false,

        builder: (context, child) {
          return AppLifecycleHandler(child: child!);
        },

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
      ),
    );
  }
}
