import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/app_repository.dart';
import '../../../core/services/reminder_service.dart';

class SettingsCubit extends Cubit<Map<String, dynamic>> {
  final AppRepository repository;
  final ReminderService reminders;
  final _revisions = <String, int>{};
  int _generation = 0;
  void cancelPendingChanges() => _generation++;
  late final StreamSubscription<Map<String, dynamic>> _subscription;
  SettingsCubit(this.repository, {ReminderService? reminders})
    : reminders = reminders ?? repository.reminders,
      super(repository.settings) {
    _subscription = repository.changes.listen((_) {
      if (!isClosed && !mapEquals(state, repository.settings)) {
        emit(repository.settings);
      }
    });
  }
  Future<bool> set(String key, dynamic value) async {
    final valid = switch (key) {
      'theme' => ['system', 'light', 'dark'].contains(value),
      'duration' => value is int && value >= 1 && value <= 180,
      'hour' => value is int && value >= 0 && value < 24,
      'minute' => value is int && value >= 0 && value < 60,
      'sound' ||
      'haptics' ||
      'daily' ||
      'streak' ||
      'onboarded' => value is bool,
      _ => false,
    };
    if (!valid || isClosed) return false;
    final generation = _generation;
    final revision = (_revisions[key] ?? 0) + 1;
    _revisions[key] = revision;
    if ((key == 'daily' || key == 'streak') && value == true) {
      try {
        if (!await reminders.requestPermission()) {
          repository.error.value = 'Notifications are not enabled. Allow them in your device settings, then try again.';
          return false;
        }
      } catch (_) {
        repository.error.value = 'Reminders are unavailable on this device.';
        return false;
      }
    }
    if (isClosed || generation != _generation || _revisions[key] != revision) {
      return false;
    }
    final saved = await repository.update(
      (d) => (d['settings'] as Map)[key] = value,
      evaluate: false,
    );
    if (saved && ['daily', 'streak', 'hour', 'minute'].contains(key)) {
      await syncReminders();
    }
    return saved;
  }

  Future<void> setTime(int hour, int minute) async {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return;
    if (await repository.update((d) {
      (d['settings'] as Map)
        ..['hour'] = hour
        ..['minute'] = minute;
    }, evaluate: false)) {
      await syncReminders();
    }
  }

  Future<void> syncReminders() async {
    try {
      final sessions = repository.sessions
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      final last = sessions.isEmpty ? null : sessions.first.completedAt;
      await reminders.sync(
        state,
        lastFocusDate: last == null
            ? null
            : '${last.year}-${last.month.toString().padLeft(2, '0')}-${last.day.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      repository.error.value = 'Your settings were saved, but reminders could not be scheduled. Please try again.';
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
