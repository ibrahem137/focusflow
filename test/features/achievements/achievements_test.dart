import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_flow/core/services/app_repository.dart';
import 'package:focus_flow/features/achievements/logic/achievement.dart';
import 'package:focus_flow/features/achievements/logic/achievements_cubit.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('all thresholds unlock once and dates survive restart', () async {
    final repository = AppRepository();
    await repository.load();
    final cubit = AchievementsCubit(repository);
    final firstDay = DateTime(2026, 1, 1, 12);
    await repository.update((d) {
      d['sessions'] = List.generate(
        30,
        (i) => {
          'id': '$i',
          'minutes': 25,
          'completedAt': firstDay.add(Duration(days: i)).toIso8601String(),
        },
      );
      d['completedTaskIds'] = List.generate(50, (i) => '$i');
    });
    expect(cubit.state.length, Achievement.all.length);
    final unlocked = Map.of(cubit.state);
    await repository.update((_) {});
    expect(cubit.state, unlocked);
    final reopened = AppRepository();
    await reopened.load();
    final restored = AchievementsCubit(reopened);
    expect(restored.state, unlocked);
    await restored.close();
    await reopened.dispose();
    await cubit.close();
    await repository.dispose();
  });
  test('values below thresholds do not unlock badges', () async {
    final repository = AppRepository();
    await repository.load();
    await repository.update((_) {});
    expect(repository.data['achievements'], isEmpty);
    await repository.dispose();
  });
}
