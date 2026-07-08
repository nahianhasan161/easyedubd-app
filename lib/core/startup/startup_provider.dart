import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'startup_controller.dart';

final startupProvider =
    AsyncNotifierProvider<StartupController, AppStartupState>(
  StartupController.new,
);