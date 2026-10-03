import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:focus_flow/core/services/app_repository.dart';
import 'package:focus_flow/core/services/reminder_service.dart';
import 'package:focus_flow/core/services/support_email_service.dart';
import 'package:focus_flow/features/focus/logic/focus_cubit.dart';
import 'package:focus_flow/features/focus/logic/focus_state.dart';
import 'package:focus_flow/features/settings/logic/settings_cubit.dart';

class PrivacyStore extends InMemorySharedPreferencesStore {
  bool failWrite = false;
  String? failRemove;
  final operations = <String>[];
  PrivacyStore() : super.empty();
  @override
  Future<bool> setValue(String type, String key, Object value) {
    operations.add('write:$key');
    return failWrite ? Future.value(false) : super.setValue(type, key, value);
  }

  @override
  Future<bool> remove(String key) {
    operations.add('remove:$key');
    return key == failRemove ? Future.value(false) : super.remove(key);
  }
}

class PrivacyReminders extends ReminderService {
  int clears = 0;
  bool fail = false;
  @override
  Future<void> clear() async {
    clears++;
    if (fail) throw StateError('Simulated native cleanup failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PrivacyStore store;
  late PrivacyReminders reminders;
  late AppRepository repository;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PrivacyStore();
    SharedPreferencesStorePlatform.instance = store;
    prefs = await SharedPreferences.getInstance();
    reminders = PrivacyReminders();
    repository = AppRepository(reminders: reminders);
  });
  tearDown(() => repository.dispose());
  Future<void> seed() async {
    await prefs.setStringList('tasks', [
      jsonEncode({
        'id': 'old-task',
        'title': 'Private task',
        'category': 'Work',
        'xp': 50,
        'isCompleted': true,
        'rewardClaimed': true,
      }),
    ]);
    await prefs.setStringList('session_history', [
      jsonEncode({
        'id': 'old-session',
        'minutes': 25,
        'completedAt': '2026-09-20T12:00:00.000',
      }),
    ]);
    await prefs.setInt('total_xp', 100);
    await prefs.setInt('selected_focus_minutes', 45);
    await prefs.setString('theme_mode', 'dark');
    await prefs.setInt('completed_sessions', 1);
    await prefs.setInt('total_focus_minutes', 25);
    store.operations.clear();
  }

  void expectClean() {
    for (final key in AppRepository.legacyKeys) {
      expect(prefs.containsKey(key), false, reason: key);
    }
  }

  test(
    'migration commits validated v2 before removing all legacy keys',
    () async {
      await seed();
      await repository.load();
      expect(store.operations.first, 'write:flutter.focus_flow_v2');
      expectClean();
      expect(repository.tasks.single.title, 'Private task');
      expect(repository.sessions.single.minutes, 25);
      expect(repository.data['xp'], 100);
      expect(repository.settings['theme'], 'dark');
      expect(
        repository.data['rewardIds'],
        containsAll(['task:old-task', 'focus:old-session']),
      );
      final restarted = AppRepository(reminders: reminders);
      await restarted.load();
      expect(restarted.data, repository.data);
      await restarted.dispose();
    },
  );
  test(
    'failed migration persistence preserves every legacy source and retries',
    () async {
      await seed();
      store.failWrite = true;
      await expectLater(repository.load(), throwsStateError);
      expect(store.operations.where((e) => e.startsWith('remove:')), isEmpty);
      for (final key in AppRepository.legacyKeys) {
        expect(prefs.containsKey(key), true);
      }
      expect(prefs.containsKey(AppRepository.storageKey), false);
      store.failWrite = false;
      await repository.load();
      expectClean();
    },
  );
  test('invalid legacy source is preserved', () async {
    await seed();
    await prefs.setStringList('tasks', ['{bad']);
    await expectLater(repository.load(), throwsFormatException);
    expect(prefs.getStringList('tasks'), ['{bad']);
    expect(prefs.containsKey(AppRepository.storageKey), false);
  });
  test('valid existing v2 cleans leftovers without remigration', () async {
    await seed();
    await prefs.setString(
      AppRepository.storageKey,
      jsonEncode(AppRepository.defaults()),
    );
    await repository.load();
    expectClean();
    expect(repository.tasks, isEmpty);
    expect(repository.data['xp'], 0);
  });
  test('invalid v2 never authorizes legacy deletion', () async {
    await seed();
    await prefs.setString(AppRepository.storageKey, '{broken');
    await expectLater(repository.load(), throwsFormatException);
    for (final key in AppRepository.legacyKeys) {
      expect(prefs.containsKey(key), true);
    }
  });
  test(
    'cleanup failure keeps v2 usable and reloads failed cache mutation',
    () async {
      await seed();
      store.failRemove = 'flutter.tasks';
      await repository.load();
      expect(repository.loaded, true);
      expect(repository.tasks, hasLength(1));
      expect(repository.error.value, contains('old local data'));
      expect(prefs.containsKey('tasks'), true);
      store.failRemove = null;
      final restarted = AppRepository(reminders: reminders);
      await restarted.load();
      expectClean();
      await restarted.dispose();
    },
  );
  test(
    'full reset clears current, legacy, and native state, preserving defaults',
    () async {
      await repository.load();
      await repository.update((d) {
        d['xp'] = 90;
        (d['settings'] as Map)['onboarded'] = true;
      });
      await seed();
      await prefs.setString('unrelated_plugin', 'keep');
      expect(await repository.reset('all'), true);
      expect(repository.data, AppRepository.defaults());
      expectClean();
      expect(reminders.clears, 1);
      expect(prefs.getString('unrelated_plugin'), 'keep');
      expect(
        jsonDecode(prefs.getString(AppRepository.storageKey)!),
        AppRepository.defaults(),
      );
    },
  );
  test(
    'legacy cleanup failure reports false and still attempts native cleanup',
    () async {
      await repository.load();
      await seed();
      store.failRemove = 'flutter.tasks';
      expect(await repository.reset('all'), false);
      expect(reminders.clears, 1);
      expect(repository.error.value, contains('Please retry'));
      expect(prefs.containsKey('tasks'), true);
      store.failRemove = null;
      expect(await repository.reset('all'), true);
      expectClean();
    },
  );
  test('native failure reports false without reviving reset timer', () async {
    await repository.load();
    final focus = FocusCubit(repository: repository);
    focus.start();
    await repository.flush();
    reminders.fail = true;
    expect(await focus.resetAllData(), false);
    expect(repository.data['active'], null);
    expect(focus.state.status, FocusStatus.ready);
    reminders.fail = false;
    expect(await focus.resetAllData(), true);
    await focus.close();
  });
  test(
    'primary write failure preserves current data and native schedules',
    () async {
      await repository.load();
      await repository.update((d) => d['xp'] = 20);
      store.failWrite = true;
      expect(await repository.reset('all'), false);
      expect(repository.data['xp'], 20);
      expect(reminders.clears, 0);
    },
  );
  test('settings shares repository native operation queue', () async {
    await repository.load();
    final settings = SettingsCubit(repository);
    expect(identical(settings.reminders, repository.reminders), true);
    await settings.close();
  });
  test('clear waits for prior scheduling and disabled sync clears', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('focus_flow/reminders');
    final gate = Completer<void>();
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'schedule') await gate.future;
          return null;
        });
    try {
      final service = ReminderService();
      final scheduling = service.sync({'daily': true});
      await Future<void>.delayed(Duration.zero);
      final clearing = service.clear();
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['schedule']);
      gate.complete();
      await scheduling;
      await clearing;
      await service.sync({
        'daily': false,
        'streak': false,
      }, lastFocusDate: '2026-09-20');
      expect(calls, ['schedule', 'clear', 'clear']);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });
  test(
    'production recipient and exact support metadata stay allowlisted',
    () async {
      final service = SupportEmailService(
        technicalInfo: () async => const SupportTechnicalInfo(
          version: '1.0.0',
          buildNumber: '1',
          platform: 'android',
        ),
      );
      final problem = await service.prepare(
        SupportRequest.problem,
        ' My report ',
      );
      expect(problem.address, 'supportfocusflow3@gmail.com');
      expect(
        problem.body,
        'My report\n\n--- Technical information (automatically included) ---\nApp: FocusFlow\nVersion: 1.0.0\nBuild: 1\nPlatform: android',
      );
      expect(
        (await service.prepare(SupportRequest.feedback, ' My feedback ')).body,
        'My feedback',
      );
      expect((await service.prepare(SupportRequest.contact, '')).body, '');
      expect(problem.uri.scheme, 'mailto');
    },
  );
  test('backup exclusions cover all supported data domains and both modern transports', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('@xml/backup_rules'));
    expect(manifest, contains('@xml/data_extraction_rules'));
    expect(manifest, isNot(contains('android.permission.INTERNET')));
    for (final name in ['backup_rules', 'data_extraction_rules']) {
      final xml = File('android/app/src/main/res/xml/$name.xml')
          .readAsStringSync();
      for (final domain in [
        'root',
        'file',
        'database',
        'sharedpref',
        'external',
        'device_root',
        'device_file',
        'device_database',
        'device_sharedpref',
      ]) {
        expect(
          'domain="$domain" path="."'.allMatches(xml).length,
          name == 'backup_rules' ? 1 : 2,
        );
      }
    }
  });
}
