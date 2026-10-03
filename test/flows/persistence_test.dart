import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_flow/core/services/app_repository.dart';
import 'package:focus_flow/features/tasks/logic/tasks_cubit.dart';
import 'package:focus_flow/features/focus/logic/focus_cubit.dart';
import 'package:focus_flow/features/focus/logic/focus_state.dart';

void main() {
  test('failed focus-history reset preserves the running session', () async {
    SharedPreferences.setMockInitialValues({});
    var fail = false;
    final repository = AppRepository(
      preferences: () {
        if (fail) throw StateError('Simulated storage failure');
        return SharedPreferences.getInstance();
      },
    );
    await repository.load();
    final focus = FocusCubit(repository: repository);
    focus.start();
    await repository.flush();
    final before = jsonEncode(repository.data['active']);
    fail = true;
    expect(await focus.resetHistory(), false);
    expect(focus.state.status, FocusStatus.running);
    expect(jsonEncode(repository.data['active']), before);
    fail = false;
    expect(await focus.resetHistory(), true);
    expect(focus.state.status, FocusStatus.ready);
    expect(repository.data['active'], null);
    await focus.close();
    await repository.dispose();
  });

  test(
    'failed timer writes restore durable state and completion retries once',
    () async {
      SharedPreferences.setMockInitialValues({});
      var fail = false;
      var now = DateTime(2026, 9, 22, 12);
      final repository = AppRepository(
        preferences: () {
          if (fail) throw StateError('Simulated storage failure');
          return SharedPreferences.getInstance();
        },
      );
      await repository.load();
      final focus = FocusCubit(repository: repository, clock: () => now);
      await focus.selectDuration(1);
      fail = true;
      focus.start();
      await repository.flush();
      await Future<void>.delayed(Duration.zero);
      expect(focus.state.status, FocusStatus.ready);
      expect(repository.data['active'], isNull);
      fail = false;
      focus.start();
      await repository.flush();
      fail = true;
      focus.pause();
      await repository.flush();
      await Future<void>.delayed(Duration.zero);
      expect(focus.state.status, FocusStatus.running);
      now = now.add(const Duration(minutes: 2));
      await focus.reconcile();
      expect(focus.state.status, FocusStatus.paused);
      expect(repository.sessions, isEmpty);
      expect(repository.data['xp'], 0);
      fail = false;
      await focus.retryCompletion();
      await focus.retryCompletion();
      expect(repository.sessions.length, 1);
      expect(repository.data['xp'], 2);
      await focus.close();
      await repository.dispose();
    },
  );
  test(
    'legacy migration preserves XP without replaying claimed rewards',
    () async {
      SharedPreferences.setMockInitialValues({
        'total_xp': 50,
        'tasks': [
          jsonEncode({
            'id': 'old',
            'title': 'Old task',
            'category': 'Work',
            'xp': 50,
            'isCompleted': true,
            'rewardClaimed': true,
          }),
        ],
      });
      final repository = AppRepository();
      await repository.load();
      final tasks = TasksCubit(repository: repository);
      expect(repository.data['xp'], 50);
      expect(await tasks.claimReward('old'), false);
      expect(repository.data['xp'], 50);
      await tasks.close();
      await repository.dispose();
    },
  );
  test('unreadable document is not overwritten', () async {
    SharedPreferences.setMockInitialValues({
      AppRepository.storageKey: '{broken',
    });
    final repository = AppRepository();
    await expectLater(repository.load(), throwsFormatException);
    expect(await repository.update((d) => d['xp'] = 10), false);
    expect(
      (await SharedPreferences.getInstance()).getString(
        AppRepository.storageKey,
      ),
      '{broken',
    );
    await repository.dispose();
  });
  test(
    'storage failure publishes no reward and retry succeeds exactly once',
    () async {
      SharedPreferences.setMockInitialValues({});
      var fail = false;
      final repository = AppRepository(
        preferences: () {
          if (fail) throw StateError('Simulated storage failure');
          return SharedPreferences.getInstance();
        },
      );
      await repository.load();
      final tasks = TasksCubit(repository: repository);
      await tasks.addTask(title: 'A', category: 'Work', xp: 40);
      final id = tasks.state.tasks.single.id;
      await tasks.toggleTask(id);
      fail = true;
      expect(await tasks.claimReward(id), false);
      expect(tasks.state.tasks.single.rewardClaimed, false);
      expect(repository.data['xp'], 0);
      expect(repository.error.value, isNotNull);
      fail = false;
      expect(await tasks.claimReward(id), true);
      expect(repository.data['xp'], 40);
      expect(await tasks.claimReward(id), false);
      await tasks.close();
      await repository.dispose();
    },
  );
}
