import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_flow/core/services/app_repository.dart';
import 'package:focus_flow/features/tasks/logic/tasks_cubit.dart';
import 'package:focus_flow/features/focus/logic/focus_cubit.dart';
import 'package:focus_flow/features/focus/logic/focus_state.dart';
import 'package:focus_flow/features/progress/logic/progress_cubit.dart';
import 'package:focus_flow/features/achievements/logic/achievements_cubit.dart';

void main() {
  late AppRepository repository;
  late TasksCubit tasks;
  late FocusCubit focus;
  late ProgressCubit progress;
  late AchievementsCubit achievements;
  late DateTime now;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = AppRepository();
    await repository.load();
    now = DateTime(2026, 9, 19, 23, 59);
    tasks = TasksCubit(repository: repository);
    focus = FocusCubit(repository: repository, clock: () => now);
    progress = ProgressCubit(repository: repository);
    achievements = AchievementsCubit(repository);
  });
  tearDown(() async {
    await focus.close();
    await tasks.close();
    await progress.close();
    await achievements.close();
    await repository.dispose();
  });
  test(
    'editing preserves task identity, reward and claimed state after restart',
    () async {
      await tasks.addTask(title: 'First title', category: 'Work', xp: 50);
      final id = tasks.state.tasks.single.id;
      await tasks.toggleTask(id);
      await tasks.claimReward(id);
      expect(
        await tasks.editTask(
          id,
          title: '  Updated title  ',
          category: 'Personal',
        ),
        true,
      );
      expect(await tasks.editTask(id, title: ' ', category: 'Work'), false);
      final restarted = AppRepository();
      await restarted.load();
      final task = restarted.tasks.single;
      expect(task.id, id);
      expect(task.title, 'Updated title');
      expect(task.xp, 50);
      expect(task.rewardClaimed, true);
      expect(await tasks.claimReward(id), false);
      expect(progress.state.totalXp, 50);
      await restarted.dispose();
    },
  );
  test(
    'existing session history prevents XP replay even with a missing receipt',
    () async {
      await repository.update((d) {
        d['sessions'] = [
          {'id': 'old', 'minutes': 1, 'completedAt': now.toIso8601String()},
        ];
        d['active'] = {
          'id': 'old',
          'minutes': 1,
          'remaining': 60,
          'running': true,
          'endsAt': now.toIso8601String(),
        };
        d['xp'] = 2;
      });
      await focus.loadFocusData();
      expect(progress.state.totalXp, 2);
      expect(focus.state.completedSessions, 1);
    },
  );
  test('fresh install has no fake tasks or statistics', () {
    expect(tasks.state.tasks, isEmpty);
    expect(focus.state.completedSessions, 0);
    expect(progress.state.totalXp, 0);
  });
  test(
    'create complete claim updates progress once even with concurrent claims',
    () async {
      await tasks.addTask(title: 'Meaningful work', category: 'Work', xp: 50);
      final id = tasks.state.tasks.single.id;
      await tasks.toggleTask(id);
      expect(progress.state.totalXp, 0);
      final claims = await Future.wait([
        tasks.claimReward(id),
        tasks.claimReward(id),
      ]);
      expect(claims.where((v) => v).length, 1);
      expect(tasks.state.tasks.single.rewardClaimed, true);
      expect(progress.state.totalXp, 50);
      expect(achievements.state.containsKey('tasks_1'), true);
      await tasks.toggleTask(id);
      await tasks.toggleTask(id);
      expect(await tasks.claimReward(id), false);
      await tasks.deleteTask(id);
      expect(progress.state.totalXp, 50);
      expect((repository.data['completedTaskIds'] as List).length, 1);
    },
  );
  test('uncomplete before claiming withdraws reward availability', () async {
    await tasks.addTask(title: 'Read', category: 'Personal', xp: 20);
    final id = tasks.state.tasks.single.id;
    await tasks.toggleTask(id);
    await tasks.toggleTask(id);
    expect(await tasks.claimReward(id), false);
    expect(progress.state.totalXp, 0);
  });
  test(
    'focus completion commits history reward garden stats and badge together',
    () async {
      await focus.selectDuration(1);
      focus.start();
      now = now.add(const Duration(minutes: 3));
      await Future.wait([focus.reconcile(), focus.reconcile()]);
      expect(focus.state.status, FocusStatus.completed);
      expect(focus.state.completedSessions, 1);
      expect(focus.state.totalFocusMinutes, 1);
      expect(
        focus.state.sessionHistory.single.completedAt,
        DateTime(2026, 9, 20),
      );
      expect(progress.state.totalXp, 2);
      expect(achievements.state.containsKey('focus_1'), true);
      final stored = jsonDecode(
        (await SharedPreferences.getInstance()).getString(
          AppRepository.storageKey,
        )!,
      ) as Map;
      expect(stored['active'], null);
      expect((stored['sessions'] as List).length, 1);
      expect(stored['xp'], 2);
      expect(focus.state.bestStreak, 1);
      await focus.reconcile();
      expect(progress.state.totalXp, 2);
    },
  );
  test(
    'restore an expired active session exactly once across two restarts',
    () async {
      await focus.selectDuration(25);
      focus.start();
      await repository.flush();
      await focus.close();
      now = now.add(const Duration(minutes: 40));
      final restoredRepository = AppRepository();
      await restoredRepository.load();
      focus = FocusCubit(repository: restoredRepository, clock: () => now);
      await focus.loadFocusData();
      expect(focus.state.remainingSeconds, 0);
      expect(restoredRepository.data['xp'], 50);
      await focus.close();
      focus = FocusCubit(repository: restoredRepository, clock: () => now);
      await focus.loadFocusData();
      expect(focus.state.completedSessions, 1);
      expect(restoredRepository.data['xp'], 50);
      addTearDown(restoredRepository.dispose);
    },
  );
  test(
    'background elapsed time, pause and restart preserve remaining time',
    () async {
      await focus.selectDuration(25);
      focus.start();
      now = now.add(const Duration(minutes: 7, seconds: 30));
      await focus.reconcile();
      expect(focus.state.remainingSeconds, 1050);
      focus.pause();
      await repository.flush();
      await focus.close();
      now = now.add(const Duration(hours: 3));
      focus = FocusCubit(repository: repository, clock: () => now);
      await focus.loadFocusData();
      expect(focus.state.status, FocusStatus.paused);
      expect(focus.state.remainingSeconds, 1050);
      focus.start();
      now = now.add(const Duration(seconds: 50));
      await focus.reconcile();
      expect(focus.state.remainingSeconds, 1000);
      focus.reset();
      await repository.flush();
      expect(repository.data['active'], null);
      expect(focus.state.completedSessions, 0);
    },
  );
  test(
    'invalid durations are ignored and a paused session cannot be resized',
    () async {
      await focus.selectDuration(0);
      await focus.selectDuration(-1);
      await focus.selectDuration(181);
      expect(focus.state.selectedMinutes, 25);
      focus.start();
      focus.pause();
      await focus.selectDuration(45);
      expect(focus.state.selectedMinutes, 25);
    },
  );
  test('reset XP does not make an old task reward claimable again', () async {
    await tasks.addTask(title: 'A', category: 'Work', xp: 50);
    final id = tasks.state.tasks.single.id;
    await tasks.toggleTask(id);
    await tasks.claimReward(id);
    await progress.resetProgress();
    expect(await tasks.claimReward(id), false);
    expect(progress.state.totalXp, 0);
  });
  test('concurrent additions are serialized without lost tasks', () async {
    await Future.wait(
      List.generate(
        20,
        (i) => tasks.addTask(title: 'Task $i', category: 'Work', xp: 20),
      ),
    );
    expect(tasks.state.tasks.length, 20);
    expect(tasks.state.tasks.map((t) => t.id).toSet().length, 20);
  });
}
