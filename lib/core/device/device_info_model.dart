class DeviceInfoModel {
  final String installationId;
  final String fingerprint;
  final String platform;
  final String model;
  final String manufacturer;
  final String osVersion;
  final String appVersion;
  final String device_name;

  const DeviceInfoModel({
    required this.installationId,
    required this.fingerprint,
    required this.platform,
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    required this.appVersion,
    required this.device_name,
  });

  Map<String, dynamic> toJson() {
    return {
      'installation_id': installationId,
      'fingerprint': fingerprint,
      'platform': platform,
      'model': model,
      'manufacturer': manufacturer,
      'os_version': osVersion,
      'app_version': appVersion,
      'device_name': device_name,
    };
  }
}
