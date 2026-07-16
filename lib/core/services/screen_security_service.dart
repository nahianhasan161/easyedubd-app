import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

enum ScreenSecurityEventType { screenshot, screenRecord }

class ScreenSecurityEvent {
  const ScreenSecurityEvent(this.type, [this.isRecording]);

  final ScreenSecurityEventType type;

  /// Only meaningful for [ScreenSecurityEventType.screenRecord].
  final bool? isRecording;

  @override
  String toString() {
    switch (type) {
      case ScreenSecurityEventType.screenshot:
        return 'Screenshot attempt detected';
      case ScreenSecurityEventType.screenRecord:
        return 'Screen recording ${isRecording == true ? 'started' : 'stopped'}';
    }
  }
}

/// Centralizes all screen-security measures:
///  - blocks screenshots / screen capture
///  - blocks screen recording (iOS)
///  - prevents data leakage by blanking the app in the app switcher /
///    when the app is backgrounded (iOS)
///
/// Emits live [eventStream] updates so a diagnostic UI can verify the
/// protection is actually working on a real device.
class ScreenSecurityService {
  ScreenSecurityService._();

  static bool _enabled = false;
  static bool _observing = false;

  static final StreamController<ScreenSecurityEvent> _eventController =
      StreamController<ScreenSecurityEvent>.broadcast();

  /// Broadcast stream of screenshot / screen-recording events (iOS only).
  static Stream<ScreenSecurityEvent> get eventStream => _eventController.stream;

  static bool get isEnabled => _enabled;

  /// Enable screenshot blocking and (on iOS) data-leakage protection.
  /// Safe to call multiple times; it is idempotent.
  static Future<void> enable() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      if (Platform.isIOS) {
        // Hide sensitive content in the app switcher / when backgrounded.
        await ScreenProtector.protectDataLeakageWithColor(Colors.white);
      }
      _enabled = true;
      await _startObserving();
    } catch (e) {
      debugPrint('ScreenSecurity: failed to enable protection: $e');
    }
  }

  /// Disable protection (used by the diagnostic screen for comparison testing).
  static Future<void> disable() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      if (Platform.isIOS) {
        await ScreenProtector.protectDataLeakageWithColorOff();
      }
      _enabled = false;
    } catch (e) {
      debugPrint('ScreenSecurity: failed to disable protection: $e');
    }
  }

  /// Re-apply protection. Some Android OEMs reset the secure flag after the
  /// app is backgrounded, so re-enable it whenever the app resumes.
  static Future<void> reapply() async {
    if (!_enabled) return;
    await enable();
  }

  static Future<void> _startObserving() async {
    if (_observing || !Platform.isIOS) return;
    _observing = true;
    try {
      // iOS-only: notifies on screenshot and screen-recording state changes.
      ScreenProtector.addListener(
        () => _eventController
            .add(const ScreenSecurityEvent(ScreenSecurityEventType.screenshot)),
        (isRecording) => _eventController.add(
          ScreenSecurityEvent(ScreenSecurityEventType.screenRecord, isRecording),
        ),
      );
    } catch (e) {
      debugPrint('ScreenSecurity: observeScreenRecording failed: $e');
    }
  }

  /// Whether the device is currently screen recording (iOS only).
  static Future<bool> isRecording() async {
    if (!Platform.isIOS) return false;
    try {
      return await ScreenProtector.isRecording();
    } catch (e) {
      debugPrint('ScreenSecurity: isRecording failed: $e');
      return false;
    }
  }
}
