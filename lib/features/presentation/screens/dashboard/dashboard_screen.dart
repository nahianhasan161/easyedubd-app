import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:easyedubd_app/shared/widgets/omi_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.watch(supabaseProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        /* leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ), */
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final GoogleSignIn signIn = GoogleSignIn.instance;

                // Sign out from Google
                //await GoogleSignIn.instance.disconnect();
                await signIn.signOut();

                // Sign out from Supabase

                await supabase.auth.signOut();
              },

              icon: const Icon(Icons.logout),

              label: const Text('Logout'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(builder: (context) => const VideoScreen()),
                );
              },

              icon: const Icon(Icons.play_arrow),

              label: const Text('Video Player'),
            ),
          ],
        ),
      ),
    );
  }
}
