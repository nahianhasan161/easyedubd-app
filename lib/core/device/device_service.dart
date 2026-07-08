import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'device_info_model.dart';

class DeviceService {
  DeviceService();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const _installationKey = 'installation_id';

  /// 1. Persistent installation ID
  Future<String> getInstallationId() async {
    final existing = await _storage.read(key: _installationKey);

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newId = const Uuid().v4();

    await _storage.write(key: _installationKey, value: newId);

    return newId;
  }

  /// 2. Full device info (MAIN METHOD YOU WILL USE)
  Future<DeviceInfoModel> getDeviceInfo() async {
    final installationId = await getInstallationId();
    final packageInfo = await PackageInfo.fromPlatform();

    String raw = '';
    String model = '';
    String manufacturer = '';
    String platform = Platform.operatingSystem;
    String osVersion = '';
    String deviceName = manufacturer.isNotEmpty
        ? '$manufacturer $model'
        : model;

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;

      model = info.model;
      manufacturer = info.manufacturer;
      osVersion = info.version.release;

      raw = [
        info.id,
        info.board,
        info.device,
        info.hardware,
        info.product,
        info.manufacturer,
        info.model,
      ].join('|');
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;

      model = info.utsname.machine;
      manufacturer = "Apple";
      osVersion = info.systemVersion;

      raw = [
        info.identifierForVendor,
        info.model,
        info.systemVersion,
      ].join('|');
    }

    if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;

      model = info.computerName;
      manufacturer = "Microsoft";
      osVersion = info.productName;

      raw = [info.deviceId, info.computerName, info.productName].join('|');
    }

    if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;

      model = info.modelName;
      manufacturer = "Apple";
      osVersion = info.osRelease;

      raw = [info.systemGUID ?? '', info.modelName, info.osRelease].join('|');
    }

    // 3. Fingerprint (hashed)
    final fingerprint = sha256.convert(utf8.encode(raw)).toString();

    return DeviceInfoModel(
      installationId: installationId,
      fingerprint: fingerprint,
      platform: platform,
      model: model,
      manufacturer: manufacturer,
      osVersion: osVersion,
      appVersion: packageInfo.version,
      device_name: deviceName,
    );
  }

  /// 3. Clear device (for logout/reset/testing)
  Future<void> clearInstallation() async {
    await _storage.delete(key: _installationKey);
  }
}
