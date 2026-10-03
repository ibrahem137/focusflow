import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_flow/core/services/app_repository.dart';
import 'package:focus_flow/core/services/reminder_service.dart';
import 'package:focus_flow/features/settings/logic/settings_cubit.dart';

class FakeReminders extends ReminderService {
  bool allowed = true;
  Completer<bool>? permission;
  int requests = 0;
  Map<String, dynamic>? scheduled;
  @override
  Future<void> clear() async {
    scheduled = null;
  }

  @override
  bool get supported => true;
  @override
  Future<bool> requestPermission() async {
    requests++;
    return permission == null ? allowed : await permission!.future;
  }

  @override
  Future<void> sync(
    Map<String, dynamic> settings, {
    String? lastFocusDate,
  }) async {
    scheduled = settings;
  }
}

void main() {
  late AppRepository repository;
  late FakeReminders reminders;
  late SettingsCubit settings;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    reminders = FakeReminders();
    repository = AppRepository(reminders: reminders);
    await repository.load();
    settings = SettingsCubit(repository, reminders: reminders);
  });
  tearDown(() async {
    await settings.close();
    await repository.dispose();
  });
  test('late permission response cannot override a later disable', () async {
    reminders.permission = Completer<bool>();
    final enabling = settings.set('daily', true);
    await settings.set('daily', false);
    reminders.permission!.complete(true);
    expect(await enabling, false);
    expect(repository.settings['daily'], false);
  });
  test('full reset invalidates pending permission requests', () async {
    reminders.permission = Completer<bool>();
    final enabling = settings.set('streak', true);
    settings.cancelPendingChanges();
    await repository.reset('all');
    reminders.permission!.complete(true);
    expect(await enabling, false);
    expect(repository.settings['streak'], false);
  });
  test('defaults and startup do not ask permission', () async {
    expect(settings.state['duration'], 25);
    expect(settings.state['theme'], 'system');
    expect(settings.state['daily'], false);
    expect(settings.state['onboarded'], false);
    await settings.syncReminders();
    expect(reminders.requests, 0);
  });
  test('settings and onboarding persist', () async {
    await settings.set('duration', 45);
    await settings.set('onboarded', true);
    await settings.set('haptics', false);
    final reopened = AppRepository();
    await reopened.load();
    expect(reopened.settings['duration'], 45);
    expect(reopened.settings['onboarded'], true);
    expect(reopened.settings['haptics'], false);
    await reopened.dispose();
  });
  test('permission denial does not enable reminders', () async {
    reminders.allowed = false;
    expect(await settings.set('daily', true), false);
    expect(settings.state['daily'], false);
    expect(reminders.requests, 1);
  });
  test('enable reschedule and disable', () async {
    await settings.set('daily', true);
    expect(reminders.scheduled!['daily'], true);
    await settings.setTime(9, 30);
    expect(reminders.scheduled!['hour'], 9);
    expect(reminders.scheduled!['minute'], 30);
    await settings.set('daily', false);
    expect(reminders.scheduled!['daily'], false);
    expect(reminders.requests, 1);
  });
  test(
    'full reset restores defaults including onboarding and reminders',
    () async {
      await settings.set('onboarded', true);
      await settings.set('daily', true);
      await repository.reset('all');
      await settings.syncReminders();
      expect(settings.state['onboarded'], false);
      expect(settings.state['daily'], false);
      expect(reminders.scheduled!['daily'], false);
    },
  );
}
