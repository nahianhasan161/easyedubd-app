import 'package:easyedubd_app/core/device/device_info_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DeviceVerificationStatus { approved, pending, revoked }

class DeviceVerificationResult {
  final String deviceId;
  final DeviceVerificationStatus status;

  const DeviceVerificationResult({
    required this.deviceId,
    required this.status,
  });
}

class DeviceRepository {
  final SupabaseClient supabase;

  DeviceRepository(this.supabase);

  Future<DeviceVerificationResult> verifyCurrentDevice(
    DeviceInfoModel device,
) async {
    final response = await supabase.rpc(
      'verify_device',
      params: {
        'p_installation_id': device.installationId,
        'p_fingerprint_hash': device.fingerprint,
        'p_platform': device.platform,
        'p_manufacturer': device.manufacturer,
        'p_model': device.model,
        'p_device_name': device.device_name,
        'p_os_version': device.osVersion,
        'p_app_version': device.appVersion,
      },
    );

    final rows = response as List;

    if (rows.isEmpty) {
      throw Exception('verify_device returned no result');
    }

    final data = rows.first as Map<String, dynamic>;

    final status = switch (data['status']) {
      'approved' => DeviceVerificationStatus.approved,
      'revoked' => DeviceVerificationStatus.revoked,
      _ => DeviceVerificationStatus.pending,
    };

    return DeviceVerificationResult(
      deviceId: data['device_id'],
      status: status,
    );
  }
}
