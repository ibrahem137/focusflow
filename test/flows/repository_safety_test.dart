import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:focus_flow/core/services/app_repository.dart';

class FailingStore extends InMemorySharedPreferencesStore {
  bool fail = false;
  FailingStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      fail ? Future.value(false) : super.setValue(valueType, key, value);
}

void main() {
  test('failed migration is not accepted from the preferences cache', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FailingStore()..fail = true;
    SharedPreferencesStorePlatform.instance = store;
    final repository = AppRepository();
    await expectLater(repository.load(), throwsStateError);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(AppRepository.storageKey), false);
    expect(repository.loaded, false);
    store.fail = false;
    await repository.load();
    expect(repository.loaded, true);
    expect(prefs.containsKey(AppRepository.storageKey), true);
    await repository.dispose();
  });
  test(
    'platform write rejection cannot leak speculative XP on restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = FailingStore();
      SharedPreferencesStorePlatform.instance = store;
      final repository = AppRepository();
      await repository.load();
      store.fail = true;
      expect(await repository.update((d) => d['xp'] = 50), false);
      final restarted = AppRepository();
      await restarted.load();
      expect(restarted.data['xp'], 0);
      store.fail = false;
      expect(await repository.update((d) => d['xp'] = 50), true);
      await restarted.dispose();
      await repository.dispose();
    },
  );
  final corruptions = <String, void Function(Map<String, dynamic>)>{
    'invalid achievement date': (d) =>
        d['achievements'] = {'focus_1': 'broken'},
    'unknown achievement': (d) => d['achievements'] = {'unknown': '2026-09-26'},
    'duplicate milestones': (d) => d['completedTaskIds'] = ['a', 'a'],
    'non-string receipt': (d) => d['rewardIds'] = [1],
    'invalid active duration': (d) => d['active'] = {
      'id': 'session',
      'minutes': -5,
      'remaining': 20,
      'running': false,
    },
    'invalid remaining time': (d) => d['active'] = {
      'id': 'session',
      'minutes': 1,
      'remaining': 120,
      'running': false,
    },
    'empty active ID': (d) => d['active'] = {
      'id': '',
      'minutes': 1,
      'remaining': 30,
      'running': false,
    },
    'unsupported version': (d) => d['version'] = 9,
  };
  for (final entry in corruptions.entries) {
    test(
      '${entry.key} preserves stored bytes and published defaults',
      () async {
        final invalid = AppRepository.defaults();
        entry.value(invalid);
        final raw = jsonEncode(invalid);
        SharedPreferences.setMockInitialValues({AppRepository.storageKey: raw});
        final repository = AppRepository();
        await expectLater(repository.load(), throwsA(isA<FormatException>()));
        expect(repository.loaded, false);
        expect(repository.data, AppRepository.defaults());
        expect(await repository.update((d) => d['xp'] = 30), false);
        expect(
          (await SharedPreferences.getInstance()).getString(
            AppRepository.storageKey,
          ),
          raw,
        );
        await repository.dispose();
      },
    );
  }
  test(
    'concurrent startup shares one initialization and one publication',
    () async {
      SharedPreferences.setMockInitialValues({});
      final gate = Completer<SharedPreferences>();
      var calls = 0;
      final repository = AppRepository(
        preferences: () {
          calls++;
          return gate.future;
        },
      );
      var publications = 0;
      final subscription = repository.changes.listen((_) => publications++);
      final loads = List.generate(10, (_) => repository.load());
      gate.complete(await SharedPreferences.getInstance());
      await Future.wait(loads);
      expect(calls, 1);
      expect(publications, 1);
      await subscription.cancel();
      await repository.dispose();
    },
  );
  test('invalid mutation does not overwrite a valid document', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = AppRepository();
    await repository.load();
    final prefs = await SharedPreferences.getInstance();
    final before = prefs.getString(AppRepository.storageKey);
    expect(await repository.update((d) => d['xp'] = -1), false);
    expect(prefs.getString(AppRepository.storageKey), before);
    expect(repository.data['xp'], 0);
    expect(await repository.update((d) => d['xp'] = 10), true);
    await repository.dispose();
  });
}
