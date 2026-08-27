import 'dart:async';

import 'package:easyedubd_app/core/cache/cache_service.dart';
import 'package:easyedubd_app/core/cache/realtime_cache_invalidator.dart';
import 'package:easyedubd_app/core/providers/auth_provider.dart';
import 'package:easyedubd_app/core/router/app_router.dart';
import 'package:easyedubd_app/core/services/app_lifecycle_handler.dart';
import 'package:easyedubd_app/core/services/screen_security_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env").timeout(
    const Duration(seconds: 5),
    onTimeout: () => Future<void>.value(),
  );

  final posthogApiKey = dotenv.env['POSTHOG_API_KEY'];
  final posthogFuture = Posthog()
      .setup(
        PostHogConfig(posthogApiKey!)
          ..host = 'https://us.i.posthog.com'
          ..debug = true
          ..captureApplicationLifecycleEvents = true
          ..sessionReplay = true
          ..sessionReplayConfig.maskAllTexts = false
          ..sessionReplayConfig.maskAllImages = false
          ..sessionReplayConfig.throttleDelay = const Duration(
            milliseconds: 5000,
          )
          ..errorTrackingConfig.captureFlutterErrors = true
          ..errorTrackingConfig.capturePlatformDispatcherErrors = true,
      )
      .timeout(
        const Duration(seconds: 5),
        onTimeout: () => Future<void>.value(),
      );

  final screenSecurityFuture = ScreenSecurityService.enable().timeout(
    const Duration(seconds: 5),
    onTimeout: () => Future<void>.value(),
  );

  await Future.wait([posthogFuture, screenSecurityFuture]);

  final rawUrl = dotenv.env['SUPABASE_URL'];
  final rawKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

  // Defensive: strip stray whitespace and any wrapping quotes that may have
  // ended up in the .env file. The Supabase client would otherwise try to
  // resolve a URL like "'https://...supabase.co'" and fail DNS lookup with
  // "No address associated with hostname".
  String? clean(String? v) {
    if (v == null) return null;
    var s = v.trim();
    if ((s.startsWith("'") && s.endsWith("'")) ||
        (s.startsWith('"') && s.endsWith('"'))) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s.isEmpty ? null : s;
  }

  final supabaseUrl = clean(rawUrl);
  final supabaseKey = clean(rawKey);

  if (supabaseUrl != null && supabaseKey != null) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Supabase initialize timeout'),
    );
  }

  // Initialize local cache and start listening for realtime updates.
  await CacheService.init().timeout(
    const Duration(seconds: 5),
    onTimeout: () => Future<void>.value(),
  );
  RealtimeCacheInvalidator.start();

  runApp(ProviderScope(
    observers: [_RiverpodErrorObserver()],
    child: const MyApp(),
  ));
}

/// Logs Riverpod provider errors and auto-recovers errored providers.
///
/// Without this observer, a provider that throws during `build()` (e.g. a
/// `FutureProvider` whose async fetch fails once and never gets invalidated)
/// stays in error state. The next `ref.watch` on it re-throws the cached
/// error, which crashes the widget tree with
/// "ProviderException: tried to use a provider that is in error state".
///
/// We log the error so it's visible in `flutter logs`, and we invalidate
/// the provider so the next access rebuilds it from scratch.
base class _RiverpodErrorObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final name = context.provider.name ?? context.provider.runtimeType;
    debugPrint('Riverpod provider "$name" failed: $error');
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
    // Invalidate so the next access rebuilds instead of re-throwing the
    // cached error.
    try {
      context.container.invalidate(context.provider);
    } catch (_) {
      // Some providers can't be invalidated (e.g. scoped ones). Swallow.
    }
  }
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
