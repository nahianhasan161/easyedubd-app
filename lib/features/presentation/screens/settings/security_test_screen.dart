import 'dart:async';
import 'dart:io';

import 'package:easyedubd_app/core/services/screen_security_service.dart';
import 'package:flutter/material.dart';

class SecurityTestScreen extends StatefulWidget {
  const SecurityTestScreen({super.key});

  @override
  State<SecurityTestScreen> createState() => _SecurityTestScreenState();
}

class _SecurityTestScreenState extends State<SecurityTestScreen> {
  bool _enabled = ScreenSecurityService.isEnabled;
  bool _isRecording = false;
  final List<String> _log = [];
  StreamSubscription<ScreenSecurityEvent>? _sub;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _sub = ScreenSecurityService.eventStream.listen((e) {
      _append(e.toString());
    });
    // iOS: poll recording state so we can surface it even without an event.
    if (Platform.isIOS) {
      _recordingTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) async {
          final recording = await ScreenSecurityService.isRecording();
          if (mounted && recording != _isRecording) {
            setState(() => _isRecording = recording);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _append(String msg) {
    if (!mounted) return;
    setState(() => _log.insert(0, '${_now()}  $msg'));
  }

  String _now() {
    final t = DateTime.now();
    return '${t.hour}:${t.minute}:${t.second}';
  }

  Future<void> _toggle(bool enable) async {
    if (enable) {
      await ScreenSecurityService.enable();
    } else {
      await ScreenSecurityService.disable();
    }
    if (mounted) setState(() => _enabled = ScreenSecurityService.isEnabled);
    _append(enable ? 'Protection ENABLED' : 'Protection DISABLED');
  }

  @override
  Widget build(BuildContext context) {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Security Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusTile(
            label: 'Platform',
            value: platform,
            ok: true,
          ),
          _StatusTile(
            label: 'Screenshot / capture block',
            value: _enabled ? 'ACTIVE' : 'OFF',
            ok: _enabled,
          ),
          _StatusTile(
            label: 'Data-leak blanking (app switcher)',
            value: _enabled ? 'ACTIVE' : 'OFF',
            ok: _enabled,
            note: Platform.isIOS
                ? 'White screen shown in app switcher.'
                : 'FLAG_SECURE blocks the recents thumbnail on Android.',
          ),
          _StatusTile(
            label: 'Screen recording',
            value: _isRecording ? 'RECORDING' : 'not recording',
            ok: !_isRecording,
            note: Platform.isIOS
                ? 'Detects iOS screen recording.'
                : 'Not detectable on Android (blocked via FLAG_SECURE).',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _enabled ? null : () => _toggle(true),
                  child: const Text('Enable'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: !_enabled ? null : () => _toggle(false),
                  child: const Text('Disable'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'How to verify manually:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Screenshot: try a system screenshot while protection is ACTIVE — '
            'the OS should refuse it ("couldn\'t capture" on Android / black '
            'image on iOS).\n'
            '• Data leakage: background the app and open the app switcher — the '
            'content should be blanked.\n'
            '• Screen recording: start a screen recording (iOS), then return to '
            'the app — the event log below should update.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Event log',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            height: 220,
            child: _log.isEmpty
                ? const Text('No events yet.')
                : ListView(
                    children: _log.map((e) => Text('• $e')).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.value,
    required this.ok,
    this.note,
  });

  final String label;
  final String value;
  final bool ok;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: note != null ? Text(note!) : null,
      trailing: Chip(
        label: Text(value),
        backgroundColor: ok ? Colors.green.shade100 : Colors.red.shade100,
      ),
    );
  }
}
