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
  int _page = 1;
  final Set<String> _busy = {};

  DevicesQuery get _query => DevicesQuery(userId: widget.userId, page: _page);

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
    ref.invalidate(userDevicesProvider(_query));
    await ref.read(userDevicesProvider(_query).future);
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
      ref.invalidate(userDevicesProvider(_query));
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
    final devicesAsync = ref.watch(userDevicesProvider(_query));

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
                loading: () => ListView(
                  children: const [
                    SizedBox(height: 80),
                    Center(child: CircularProgressIndicator()),
                  ],
                ),
                 error: (e, _) => ListView(
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('Error: $e'),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                data: (page) {
                  if (page.items.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text('No devices registered for this user.'),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: page.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final device = page.items[index];
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
                        ),
                      ),
                      _DevicesPaginationBar(
                        page: page,
                        onPrevious: _page > 1
                            ? () => setState(() => _page--)
                            : null,
                        onNext: _page < page.totalPages
                            ? () => setState(() => _page++)
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _DevicesPaginationBar extends StatelessWidget {
  const _DevicesPaginationBar({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final PaginatedDevices page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final totalPages = page.totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${page.start}–${page.end} of ${page.total}',
            style: const TextStyle(fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              Text('Page ${page.page} of ${totalPages == 0 ? 1 : totalPages}'),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
