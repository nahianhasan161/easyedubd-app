import 'package:easyedubd_app/core/providers/auth_provider.dart';
import 'package:easyedubd_app/core/router/app_router.dart';
import 'package:easyedubd_app/core/services/app_lifecycle_handler.dart';
import 'package:easyedubd_app/core/services/screen_security_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ScreenSecurityService.enable();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY'],
  );

  runApp(const ProviderScope(child: MyApp()));
}

final supabase = Supabase.instance.client;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the auth-reset listener active so user-scoped caches are cleared
    // when the signed-in account changes (prevents showing old account data).
    ref.watch(authResetProvider);

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Easy Education Bangladesh',
      routerConfig: router,
      debugShowCheckedModeBanner: false,

      builder: (context, child) {
        return AppLifecycleHandler(child: child!);
      },

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}
