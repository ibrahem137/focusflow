import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/focus/logic/focus_state.dart';
import 'package:focus_flow/features/focus/data/models/focus_session.dart';

void main() {
  test('best streak handles duplicate dates, gaps and year boundaries', () {
    final dates = [
      DateTime(2025, 12, 30),
      DateTime(2025, 12, 31),
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 1, 18),
      DateTime(2026, 1, 3),
    ];
    final state = FocusState.initial().copyWith(
      sessionHistory: [
        for (var i = 0; i < dates.length; i++)
          FocusSession(id: '$i', minutes: 25, completedAt: dates[i]),
      ],
    );
    expect(state.bestStreak, 3);
    expect(state.averageSessionMinutes, 25);
    expect(state.mostProductiveDay, '2026-01-01');
  });
  test('empty history has safe averages and best streak', () {
    final state = FocusState.initial();
    expect(state.bestStreak, 0);
    expect(state.averageDailyMinutes, 0);
    expect(state.averageSessionMinutes, 0);
    expect(state.mostProductiveDay, '—');
  });
}
