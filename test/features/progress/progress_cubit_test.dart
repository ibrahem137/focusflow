import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/progress/logic/progress_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProgressCubit progressCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    progressCubit = ProgressCubit();
  });

  tearDown(() async {
    await progressCubit.close();
  });

  test('initial state starts with 0 XP and level 1', () {
    expect(progressCubit.state.totalXp, 0);
    expect(progressCubit.state.level, 1);
    expect(progressCubit.state.currentLevelXp, 0);
    expect(progressCubit.state.levelProgress, 0);
    expect(progressCubit.state.remainingXp, 1000);
  });

  test('addXp adds XP correctly', () async {
    await progressCubit.addXp(50);

    expect(progressCubit.state.totalXp, 50);
    expect(progressCubit.state.level, 1);
    expect(progressCubit.state.currentLevelXp, 50);
    expect(progressCubit.state.remainingXp, 950);
  });

  test('addXp ignores zero and negative values', () async {
    await progressCubit.addXp(0);
    await progressCubit.addXp(-100);

    expect(progressCubit.state.totalXp, 0);
  });

  test('999 XP keeps user at level 1', () async {
    await progressCubit.addXp(999);

    expect(progressCubit.state.totalXp, 999);
    expect(progressCubit.state.level, 1);
    expect(progressCubit.state.currentLevelXp, 999);
    expect(progressCubit.state.remainingXp, 1);
  });

  test('1000 XP moves user to level 2', () async {
    await progressCubit.addXp(1000);

    expect(progressCubit.state.totalXp, 1000);
    expect(progressCubit.state.level, 2);
    expect(progressCubit.state.currentLevelXp, 0);
    expect(progressCubit.state.remainingXp, 1000);
    expect(progressCubit.state.levelProgress, 0);
  });

  test('2500 XP results in level 3 with 500 current level XP', () async {
    await progressCubit.addXp(2500);

    expect(progressCubit.state.totalXp, 2500);
    expect(progressCubit.state.level, 3);
    expect(progressCubit.state.currentLevelXp, 500);
    expect(progressCubit.state.remainingXp, 500);
    expect(progressCubit.state.levelProgress, 0.5);
  });

  test('resetProgress resets XP and level', () async {
    await progressCubit.addXp(1500);

    expect(progressCubit.state.totalXp, 1500);
    expect(progressCubit.state.level, 2);

    await progressCubit.resetProgress();

    expect(progressCubit.state.totalXp, 0);
    expect(progressCubit.state.level, 1);
    expect(progressCubit.state.currentLevelXp, 0);
  });

  test('XP persists after creating a new cubit', () async {
    // Arrange
    await progressCubit.addXp(1250);

    // Act
    final newCubit = ProgressCubit();

    await newCubit.loadProgress();

    // Assert
    expect(newCubit.state.totalXp, 1250);
    expect(newCubit.state.level, 2);
    expect(newCubit.state.currentLevelXp, 250);
    expect(newCubit.state.remainingXp, 750);
    expect(newCubit.state.levelProgress, 0.25);

    await newCubit.close();
  });
}
