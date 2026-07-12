import 'package:easyedubd_app/features/presentation/screens/admin/user_device.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_device_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserDevicesScreen extends ConsumerStatefulWidget {
  const UserDevicesScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  ConsumerState<UserDevicesScreen> createState() => _UserDevicesScreenState();
}

class _UserDevicesScreenState extends ConsumerState<UserDevicesScreen> {
  final Set<String> _busy = {};

  (IconData, Color, String) _statusVisual(DeviceStatus status) => switch (status) {
        DeviceStatus.approved => (
          Icons.verified_user,
          Colors.green,
          'Approved',
        ),
        DeviceStatus.pending => (
          Icons.pending_outlined,
          Colors.orange,
          'Pending approval',
        ),
        DeviceStatus.blocked => (
          Icons.block,
          Colors.red,
          'Blocked',
        ),
      };

  Future<void> _refresh() async {
    ref.invalidate(userDevicesProvider(widget.userId));
    await ref.read(userDevicesProvider(widget.userId).future);
  }

  Future<void> _setStatus(UserDevice device, DeviceStatus newStatus) async {
    final adminId = ref.read(currentUserIdProvider);
    if (adminId == null) return;

    final approved = newStatus == DeviceStatus.approved;
    final revokedAt = newStatus == DeviceStatus.blocked ? DateTime.now() : null;

    setState(() => _busy.add(device.id));
    try {
      await ref.read(userRepositoryProvider).setDeviceApproved(
            deviceId: device.id,
            approved: approved,
            adminId: adminId,
            revokedAt: revokedAt,
          );
      ref.invalidate(userDevicesProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device set to ${newStatus.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(device.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final devicesAsync = ref.watch(userDevicesProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(title: Text('Devices · ${widget.userName}')),
      body: !isAdmin
          ? const Center(
              child: Text(
                'You do not have permission to view this page.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: devicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $e'),
                  ),
                ),
                data: (devices) {
                  if (devices.isEmpty) {
                    return const Center(
                      child: Text('No devices registered for this user.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                    final title = device.deviceName?.isNotEmpty == true
                        ? device.deviceName!
                        : '${device.manufacturer ?? ''} ${device.model ?? ''}'
                            .trim()
                            .isEmpty
                        ? device.platform
                        : '${device.manufacturer} ${device.model}';
                    final subtitle = [
                      device.platform,
                      if (device.osVersion?.isNotEmpty == true)
                        'OS ${device.osVersion}',
                      if (device.appVersion?.isNotEmpty == true)
                        'App ${device.appVersion}',
                    ].where((e) => e.isNotEmpty).join(' · ');

                    final status = device.status;
                    final (IconData icon, Color color, String label) =
                        _statusVisual(status);

                    return ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          if (subtitle.isNotEmpty) Text(subtitle),
                          Text(
                            'ID: ${device.installationId}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: _busy.contains(device.id)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : DropdownButton<DeviceStatus>(
                              value: status,
                              isDense: true,
                              underline: const SizedBox.shrink(),
                              items: DeviceStatus.values.map((s) {
                                final (_, __, itemLabel) = _statusVisual(s);
                                return DropdownMenuItem(
                                  key: Key('${device.id}_${s.name}'),
                                  value: s,
                                  child: Text(itemLabel),
                                );
                              }).toList(),
                              onChanged: (selected) {
                                if (selected != null && selected != status) {
                                  _setStatus(device, selected);
                                }
                              },
                            ),
                    );
                    },
                  );
                },
              ),
            ),
    );
  }
}
