import 'package:easyedubd_app/core/router/app_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await DefaultCacheManager().emptyCache();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,

    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY'],
  );
  runApp(const ProviderScope(child: MyApp()));
}

final supabase = Supabase.instance.client;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Easy Education BD',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}
