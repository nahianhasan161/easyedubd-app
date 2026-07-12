enum DeviceStatus { approved, pending, blocked }

class UserDevice {
  final String id;
  final String userId;
  final String installationId;
  final String? fingerprintHash;
  final String platform;
  final String? manufacturer;
  final String? model;
  final String? deviceName;
  final String? osVersion;
  final String? appVersion;
  final bool approved;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final String? ipAddress;

  const UserDevice({
    required this.id,
    required this.userId,
    required this.installationId,
    this.fingerprintHash,
    required this.platform,
    this.manufacturer,
    this.model,
    this.deviceName,
    this.osVersion,
    this.appVersion,
    required this.approved,
    this.approvedAt,
    this.approvedBy,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.revokedAt,
    required this.createdAt,
    this.ipAddress,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    final parse = (v) =>
        v == null ? null : DateTime.parse(v as String);

    return UserDevice(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      installationId: json['installation_id'] as String,
      fingerprintHash: json['fingerprint_hash'] as String?,
      platform: json['platform'] as String,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      deviceName: json['device_name'] as String?,
      osVersion: json['os_version'] as String?,
      appVersion: json['app_version'] as String?,
      approved: json['approved'] as bool? ?? false,
      approvedAt: parse(json['approved_at']),
      approvedBy: json['approved_by'] as String?,
      firstSeenAt: parse(json['first_seen_at'])!,
      lastSeenAt: parse(json['last_seen_at'])!,
      revokedAt: parse(json['revoked_at']),
      createdAt: parse(json['created_at'])!,
      ipAddress: json['ip_address'] as String?,
    );
  }

  UserDevice copyWith({bool? approved, DateTime? approvedAt, String? approvedBy, DateTime? revokedAt}) {
    return UserDevice(
      id: id,
      userId: userId,
      installationId: installationId,
      fingerprintHash: fingerprintHash,
      platform: platform,
      manufacturer: manufacturer,
      model: model,
      deviceName: deviceName,
      osVersion: osVersion,
      appVersion: appVersion,
      approved: approved ?? this.approved,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      firstSeenAt: firstSeenAt,
      lastSeenAt: lastSeenAt,
      revokedAt: revokedAt ?? this.revokedAt,
      createdAt: createdAt,
      ipAddress: ipAddress,
    );
  }

  DeviceStatus get status {
    if (approved) return DeviceStatus.approved;
    if (revokedAt != null) return DeviceStatus.blocked;
    return DeviceStatus.pending;
  }
}
