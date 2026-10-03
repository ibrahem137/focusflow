import '../../helpers/fixtures.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/tasks/logic/tasks_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late TasksCubit tasksCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues(legacyTaskFixture());

    tasksCubit = TasksCubit();
    await tasksCubit.loadTasks();
  });

  tearDown(() async {
    await tasksCubit.close();
  });

  test('loads 3 persisted fixture tasks', () {
    expect(tasksCubit.state.tasks.length, 3);
  });
  test('addTask adds a new task', () async {
    // Arrange
    const title = 'Learn Flutter Testing';

    // Act
    await tasksCubit.addTask(title: title, category: 'Learning', xp: 50);

    // Assert
    expect(tasksCubit.state.tasks.length, 4);

    expect(tasksCubit.state.tasks.last.title, title);

    expect(tasksCubit.state.tasks.last.category, 'Learning');

    expect(tasksCubit.state.tasks.last.xp, 50);
  });
  test('addTask does not add a task when title is empty', () async {
    // Arrange
    final initialCount = tasksCubit.state.tasks.length;

    // Act
    await tasksCubit.addTask(title: '   ', category: 'Learning', xp: 50);

    // Assert
    expect(tasksCubit.state.tasks.length, initialCount);
  });
  test('toggleTask changes task completion state', () async {
    // Arrange
    final task = tasksCubit.state.tasks.first;

    expect(task.isCompleted, false);

    // Act
    await tasksCubit.toggleTask(task.id);

    // Assert
    final updatedTask = tasksCubit.state.tasks.first;

    expect(updatedTask.isCompleted, true);
  });
  test('claimReward marks completed task reward as claimed', () async {
    final cubit = TasksCubit();

    await cubit.toggleTask('1');

    final claimed = await cubit.claimReward('1');

    expect(claimed, isTrue);

    final task = cubit.state.tasks.firstWhere((task) => task.id == '1');

    expect(task.isCompleted, isTrue);
    expect(task.rewardClaimed, isTrue);

    await cubit.close();
  });
  test('cannot claim reward for incomplete task', () async {
    final cubit = TasksCubit();

    final claimed = await cubit.claimReward('1');

    expect(claimed, isFalse);

    final task = cubit.state.tasks.firstWhere((task) => task.id == '1');

    expect(task.isCompleted, isFalse);
    expect(task.rewardClaimed, isFalse);

    await cubit.close();
  });

  test('completed task reward can be claimed once', () async {
    final cubit = TasksCubit();

    await cubit.toggleTask('1');

    final firstClaim = await cubit.claimReward('1');
    final secondClaim = await cubit.claimReward('1');

    expect(firstClaim, isTrue);
    expect(secondClaim, isFalse);

    final task = cubit.state.tasks.firstWhere((task) => task.id == '1');

    expect(task.isCompleted, isTrue);
    expect(task.rewardClaimed, isTrue);

    await cubit.close();
  });

  test(
    'reward stays claimed after uncompleting and completing task again',
    () async {
      final cubit = TasksCubit();

      // Complete
      await cubit.toggleTask('1');

      final firstClaim = await cubit.claimReward('1');

      expect(firstClaim, isTrue);

      // Uncomplete
      await cubit.toggleTask('1');

      // Complete again
      await cubit.toggleTask('1');

      final secondClaim = await cubit.claimReward('1');

      expect(secondClaim, isFalse);

      final task = cubit.state.tasks.firstWhere((task) => task.id == '1');

      expect(task.isCompleted, isTrue);
      expect(task.rewardClaimed, isTrue);

      await cubit.close();
    },
  );
  test('deleteTask removes task', () async {
    // Arrange
    final task = tasksCubit.state.tasks.first;

    final initialCount = tasksCubit.state.tasks.length;

    // Act
    await tasksCubit.deleteTask(task.id);

    // Assert
    expect(tasksCubit.state.tasks.length, initialCount - 1);

    expect(tasksCubit.state.tasks.any((item) => item.id == task.id), false);
  });
  test('tasks persist after creating a new cubit', () async {
    // Arrange
    await tasksCubit.addTask(
      title: 'Persistent Task',
      category: 'Learning',
      xp: 100,
    );

    final addedTask = tasksCubit.state.tasks.last;

    await tasksCubit.toggleTask(addedTask.id);

    await tasksCubit.claimReward(addedTask.id);

    // Act
    final newCubit = TasksCubit();

    await newCubit.loadTasks();

    // Assert
    expect(newCubit.state.tasks.length, 4);

    final restoredTask = newCubit.state.tasks.last;

    expect(restoredTask.title, 'Persistent Task');

    expect(restoredTask.category, 'Learning');

    expect(restoredTask.xp, 100);

    expect(restoredTask.isCompleted, true);

    expect(restoredTask.rewardClaimed, true);

    await newCubit.close();
  });
}
