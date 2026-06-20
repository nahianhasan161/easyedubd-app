// Add this helper inside your router provider file
import 'package:easyedubd_app/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authListenable = Provider<Listenable>((ref) {
  final controller = ChangeNotifier();
  ref.listen(authStateProvider, (_, __) => controller.notifyListeners());
  return controller;
});