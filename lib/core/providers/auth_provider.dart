import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.onAuthStateChange.map((event) => event.session);
});
