import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/focus/data/models/focus_session.dart';
import 'package:focus_flow/features/focus/logic/focus_cubit.dart';
import 'package:focus_flow/features/focus/logic/focus_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FocusCubit focusCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    focusCubit = FocusCubit();
  });

  tearDown(() async {
    await focusCubit.close();
  });

  test('initial state has correct default values', () {
    expect(focusCubit.state.selectedMinutes, 25);
    expect(focusCubit.state.remainingSeconds, 25 * 60);
    expect(focusCubit.state.status, FocusStatus.ready);
    expect(focusCubit.state.completedSessions, 0);
    expect(focusCubit.state.totalFocusMinutes, 0);
    expect(focusCubit.state.sessionHistory, isEmpty);
  });

  test('selectDuration changes selected duration', () async {
    await focusCubit.selectDuration(45);

    expect(focusCubit.state.selectedMinutes, 45);
    expect(focusCubit.state.remainingSeconds, 45 * 60);
    expect(focusCubit.state.status, FocusStatus.ready);
  });

  test('start changes status to running', () {
    focusCubit.start();

    expect(focusCubit.state.status, FocusStatus.running);
  });

  test('pause changes running session to paused', () {
    focusCubit.start();
    focusCubit.pause();

    expect(focusCubit.state.status, FocusStatus.paused);
  });

  test('reset returns timer to selected duration', () async {
    await focusCubit.selectDuration(1);

    focusCubit.start();

    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(focusCubit.state.remainingSeconds, lessThan(60));

    focusCubit.reset();

    expect(focusCubit.state.remainingSeconds, 60);
    expect(focusCubit.state.status, FocusStatus.ready);

    expect(focusCubit.state.completedSessions, 0);
    expect(focusCubit.state.totalFocusMinutes, 0);
  });
  test('pause stops the timer from counting down', () async {
    await focusCubit.selectDuration(1);

    focusCubit.start();

    await Future<void>.delayed(const Duration(milliseconds: 1100));

    focusCubit.pause();

    final secondsWhenPaused = focusCubit.state.remainingSeconds;

    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(focusCubit.state.remainingSeconds, secondsWhenPaused);

    expect(focusCubit.state.status, FocusStatus.paused);
  });
  test('selectDuration does nothing while timer is running', () async {
    await focusCubit.selectDuration(1);

    focusCubit.start();

    await focusCubit.selectDuration(45);

    expect(focusCubit.state.selectedMinutes, 1);

    expect(focusCubit.state.status, FocusStatus.running);
  });
  test('selected focus duration persists after creating a new cubit', () async {
    // Arrange
    await focusCubit.selectDuration(45);

    // Act
    final newCubit = FocusCubit();

    await newCubit.loadFocusData();

    // Assert
    expect(newCubit.state.selectedMinutes, 45);

    expect(newCubit.state.remainingSeconds, 45 * 60);

    expect(newCubit.state.status, FocusStatus.ready);

    await newCubit.close();
  });
  test('completing a session updates focus statistics and history', () async {
    // Arrange
    var now = DateTime.now();
    final fastCubit = FocusCubit(clock: () => now);

    await fastCubit.selectDuration(1);

    // Act
    fastCubit.start();

    now = now.add(const Duration(minutes: 1));
    await fastCubit.reconcile();

    // Assert
    expect(fastCubit.state.status, FocusStatus.completed);

    expect(fastCubit.state.remainingSeconds, 0);

    expect(fastCubit.state.completedSessions, 1);

    expect(fastCubit.state.totalFocusMinutes, 1);

    expect(fastCubit.state.sessionHistory.length, 1);

    final session = fastCubit.state.sessionHistory.first;

    expect(session.minutes, 1);

    await fastCubit.close();
  });
  test('completed session is counted only once', () async {
    var now = DateTime.now();
    final fastCubit = FocusCubit(clock: () => now);

    await fastCubit.selectDuration(1);

    fastCubit.start();

    now = now.add(const Duration(minutes: 1));
    await fastCubit.reconcile();

    expect(fastCubit.state.completedSessions, 1);

    expect(fastCubit.state.sessionHistory.length, 1);

    // ننتظر أكثر للتأكد أن الـTimer توقف فعلًا.
    now = now.add(const Duration(minutes: 1));
    await fastCubit.reconcile();

    expect(fastCubit.state.completedSessions, 1);

    expect(fastCubit.state.totalFocusMinutes, 1);

    expect(fastCubit.state.sessionHistory.length, 1);

    await fastCubit.close();
  });
  test('completed session is included in weekly focus minutes', () async {
    var now = DateTime.now();
    final fastCubit = FocusCubit(clock: () => now);

    await fastCubit.selectDuration(1);

    fastCubit.start();

    now = now.add(const Duration(minutes: 1));
    await fastCubit.reconcile();

    final todayIndex = DateTime.now().weekday - 1;

    expect(fastCubit.state.weeklyFocusMinutes[todayIndex], 1);

    expect(fastCubit.state.weeklyTotalMinutes, 1);

    await fastCubit.close();
  });
  test('completed session persists after creating a new cubit', () async {
    var now = DateTime.now();
    final fastCubit = FocusCubit(clock: () => now);

    await fastCubit.selectDuration(1);

    fastCubit.start();

    now = now.add(const Duration(minutes: 1));
    await fastCubit.reconcile();

    expect(fastCubit.state.completedSessions, 1);

    await fastCubit.close();

    // Simulate reopening the app.
    final restoredCubit = FocusCubit();

    await restoredCubit.loadFocusData();

    expect(restoredCubit.state.completedSessions, 1);

    expect(restoredCubit.state.totalFocusMinutes, 1);

    expect(restoredCubit.state.sessionHistory.length, 1);

    expect(restoredCubit.state.sessionHistory.first.minutes, 1);

    final todayIndex = DateTime.now().weekday - 1;

    expect(restoredCubit.state.weeklyFocusMinutes[todayIndex], 1);

    await restoredCubit.close();
  });
  group('FocusState statistics', () {
    FocusSession createSession({
      required String id,
      required int minutes,
      required DateTime completedAt,
    }) {
      return FocusSession(id: id, minutes: minutes, completedAt: completedAt);
    }

    test('today statistics count only sessions completed today', () {
      final now = DateTime.now();

      final yesterday = now.subtract(const Duration(days: 1));

      final state = FocusState.initial().copyWith(
        completedSessions: 3,
        totalFocusMinutes: 75,
        sessionHistory: [
          createSession(id: '1', minutes: 25, completedAt: now),
          createSession(id: '2', minutes: 30, completedAt: now),
          createSession(id: '3', minutes: 20, completedAt: yesterday),
        ],
      );

      expect(state.todayCompletedSessions, 2);
      expect(state.todayFocusMinutes, 55);
      expect(state.hasFocusedToday, isTrue);
    });

    test('today statistics are zero when there are no sessions today', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      final state = FocusState.initial().copyWith(
        sessionHistory: [
          createSession(id: '1', minutes: 25, completedAt: yesterday),
        ],
      );

      expect(state.todayCompletedSessions, 0);
      expect(state.todayFocusMinutes, 0);
      expect(state.hasFocusedToday, isFalse);
    });

    test('weekly focus minutes are grouped by weekday', () {
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final monday = today.subtract(Duration(days: today.weekday - 1));

      final tuesday = monday.add(const Duration(days: 1));

      final state = FocusState.initial().copyWith(
        sessionHistory: [
          createSession(id: '1', minutes: 25, completedAt: monday),
          createSession(id: '2', minutes: 20, completedAt: monday),
          createSession(id: '3', minutes: 45, completedAt: tuesday),
        ],
      );

      expect(state.weeklyFocusMinutes[0], 45);
      expect(state.weeklyFocusMinutes[1], 45);
      expect(state.weeklyTotalMinutes, 90);
    });

    test('weekly session counts are grouped by weekday', () {
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final monday = today.subtract(Duration(days: today.weekday - 1));

      final wednesday = monday.add(const Duration(days: 2));

      final state = FocusState.initial().copyWith(
        sessionHistory: [
          createSession(id: '1', minutes: 25, completedAt: monday),
          createSession(id: '2', minutes: 25, completedAt: monday),
          createSession(id: '3', minutes: 45, completedAt: wednesday),
        ],
      );

      expect(state.weeklySessionCounts[0], 2);
      expect(state.weeklySessionCounts[2], 1);
      expect(state.weeklyTotalSessions, 3);
    });

    test('sessions from previous week are excluded from current week', () {
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final monday = today.subtract(Duration(days: today.weekday - 1));

      final previousSunday = monday.subtract(const Duration(days: 1));

      final state = FocusState.initial().copyWith(
        sessionHistory: [
          createSession(id: 'old', minutes: 60, completedAt: previousSunday),
          createSession(id: 'current', minutes: 25, completedAt: monday),
        ],
      );

      expect(state.weeklyFocusMinutes[0], 25);
      expect(state.weeklyTotalMinutes, 25);

      expect(state.weeklySessionCounts[0], 1);
      expect(state.weeklyTotalSessions, 1);
    });

    test('current streak counts consecutive days including today', () {
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final yesterday = today.subtract(const Duration(days: 1));

      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final state = FocusState.initial().copyWith(
        sessionHistory: [
          createSession(id: '1', minutes: 25, completedAt: twoDaysAgo),
          createSession(id: '2', minutes: 25, completedAt: yesterday),
          createSession(id: '3', minutes: 25, completedAt: today),
        ],
      );

      expect(state.currentStreak, 3);
    });

    test(
      'current streak stays active when last focus session was yesterday',
      () {
        final now = DateTime.now();

        final today = DateTime(now.year, now.month, now.day);

        final yesterday = today.subtract(const Duration(days: 1));

        final twoDaysAgo = today.subtract(const Duration(days: 2));

        final state = FocusState.initial().copyWith(
          sessionHistory: [
            createSession(id: '1', minutes: 25, completedAt: twoDaysAgo),
            createSession(id: '2', minutes: 25, completedAt: yesterday),
          ],
        );

        expect(state.currentStreak, 2);
        expect(state.hasFocusedToday, isFalse);
      },
    );

    test('current streak is zero when streak is broken', () {
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final threeDaysAgo = today.subtract(const Duration(days: 3));

      final state = FocusState.initial().copyWith(
        sessionHistory: [
          createSession(id: '1', minutes: 25, completedAt: threeDaysAgo),
        ],
      );

      expect(state.currentStreak, 0);
    });

    test('multiple sessions on same day count as one streak day', () {
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final yesterday = today.subtract(const Duration(days: 1));

      final state = FocusState.initial().copyWith(
        sessionHistory: [
          createSession(id: '1', minutes: 25, completedAt: yesterday),
          createSession(id: '2', minutes: 45, completedAt: today),
          createSession(
            id: '3',
            minutes: 25,
            completedAt: today.add(const Duration(hours: 2)),
          ),
        ],
      );

      expect(state.todayCompletedSessions, 2);
      expect(state.todayFocusMinutes, 70);

      // Yesterday + today = 2 days,
      // not 3 sessions.
      expect(state.currentStreak, 2);
    });

    test('empty session history has zero statistics and zero streak', () {
      final state = FocusState.initial();

      expect(state.todayCompletedSessions, 0);
      expect(state.todayFocusMinutes, 0);
      expect(state.hasFocusedToday, isFalse);

      expect(state.weeklyFocusMinutes, everyElement(0));

      expect(state.weeklySessionCounts, everyElement(0));

      expect(state.weeklyTotalMinutes, 0);
      expect(state.weeklyTotalSessions, 0);
      expect(state.currentStreak, 0);
    });
  });
}
