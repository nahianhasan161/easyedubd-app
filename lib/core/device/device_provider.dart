import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/supabase_provider.dart';
import 'device_repository.dart';
import 'device_service.dart';

final deviceServiceProvider = Provider((ref) {
  return DeviceService();
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return DeviceRepository(supabase);
});
