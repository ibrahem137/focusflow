import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android uses inexact local-calendar alarms, iOS calendar notifications.
/// Unsupported platforms expose no pretend scheduling toggle.
class ReminderService {
  static const _channel = MethodChannel('focus_flow/reminders');
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<bool> requestPermission() async {
    if (!supported) return false;
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  Future<void> _pending = Future<void>.value();
  Future<void> sync(Map<String, dynamic> settings, {String? lastFocusDate}) {
    if (!supported) return Future<void>.value();
    if (settings['daily'] != true && settings['streak'] != true) return clear();
    final operation = _pending.then(
      (_) => _channel.invokeMethod<void>('schedule', {
        ...settings,
        'lastFocusDate': lastFocusDate,
      }),
    );
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> clear() {
    if (!supported) return Future<void>.value();
    final operation = _pending.then(
      (_) => _channel.invokeMethod<void>('clear'),
    );
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> complete({required bool sound, required bool haptics}) async {
    if (haptics) await HapticFeedback.mediumImpact();
    if (sound && supported) await _channel.invokeMethod<void>('playSound');
  }
}
