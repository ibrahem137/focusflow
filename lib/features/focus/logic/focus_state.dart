import '../data/models/focus_session.dart';

class FocusState {
  final int selectedMinutes;
  final int remainingSeconds;
  final FocusStatus status;
  final int completedSessions;
  final int totalFocusMinutes;
  final List<FocusSession> sessionHistory;

  const FocusState({
    required this.selectedMinutes,
    required this.remainingSeconds,
    required this.status,
    required this.completedSessions,
    required this.totalFocusMinutes,
    required this.sessionHistory,
  });

  factory FocusState.initial() {
    return const FocusState(
      selectedMinutes: 25,
      remainingSeconds: 25 * 60,
      status: FocusStatus.ready,
      completedSessions: 0,
      totalFocusMinutes: 0,
      sessionHistory: [],
    );
  }

  int get bestStreak {
    final days =
        sessionHistory.map((s) => _dateOnly(s.completedAt)).toSet().toList()
          ..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final day in days) {
      run = previous != null && day.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > best) best = run;
      previous = day;
    }
    return best;
  }

  double get averageSessionMinutes => sessionHistory.isEmpty
      ? 0
      : sessionHistory.fold<int>(0, (n, s) => n + s.minutes) /
            sessionHistory.length;

  double get averageDailyMinutes {
    if (sessionHistory.isEmpty) return 0;
    final days = sessionHistory.map((s) => _dateOnly(s.completedAt)).toList()
      ..sort();
    final count = _dateOnly(DateTime.now()).difference(days.first).inDays + 1;
    return sessionHistory.fold<int>(0, (n, s) => n + s.minutes) /
        (count < 1 ? 1 : count);
  }

  String get mostProductiveDay {
    if (sessionHistory.isEmpty) return '—';
    final totals = <DateTime, int>{};
    for (final s in sessionHistory) {
      final day = _dateOnly(s.completedAt);
      totals[day] = (totals[day] ?? 0) + s.minutes;
    }
    final days = totals.keys.toList()
      ..sort((a, b) {
        final result = totals[b]!.compareTo(totals[a]!);
        return result == 0 ? a.compareTo(b) : result;
      });
    return days.first.toIso8601String().split('T').first;
  }

  // ===========================================================================
  // Streak
  // ===========================================================================

  int get currentStreak {
    if (sessionHistory.isEmpty) {
      return 0;
    }

    final focusedDays = sessionHistory
        .map((session) => _dateOnly(session.completedAt))
        .toSet();

    if (focusedDays.isEmpty) {
      return 0;
    }

    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime cursor;

    if (focusedDays.contains(today)) {
      cursor = today;
    } else if (focusedDays.contains(yesterday)) {
      // The streak is still alive if the user focused yesterday
      // but has not focused yet today.
      cursor = yesterday;
    } else {
      return 0;
    }

    var streak = 0;

    while (focusedDays.contains(cursor)) {
      streak++;

      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // ===========================================================================
  // Timer
  // ===========================================================================

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  bool get hasFocusedToday {
    return todaySessions.isNotEmpty;
  }

  bool get isRunning => status == FocusStatus.running;

  double get progress {
    final totalSeconds = selectedMinutes * 60;

    if (totalSeconds <= 0) {
      return 0;
    }

    final value = 1 - (remainingSeconds / totalSeconds);

    return value.clamp(0.0, 1.0);
  }

  int get todayCompletedSessions {
    return todaySessions.length;
  }

  int get todayFocusMinutes {
    return todaySessions.fold<int>(
      0,
      (total, session) => total + session.minutes,
    );
  }

  // ===========================================================================
  // Today
  // ===========================================================================

  List<FocusSession> get todaySessions {
    final now = DateTime.now();

    return sessionHistory.where((session) {
      return _isSameDay(session.completedAt, now);
    }).toList();
  }

  // ===========================================================================
  // Current Week
  // ===========================================================================

  List<int> get weeklyFocusMinutes {
    final now = DateTime.now();
    final today = _dateOnly(now);

    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return List.generate(7, (index) {
      final day = startOfWeek.add(Duration(days: index));

      return sessionHistory
          .where((session) => _isSameDay(session.completedAt, day))
          .fold<int>(0, (total, session) => total + session.minutes);
    });
  }

  List<int> get weeklySessionCounts {
    final now = DateTime.now();
    final today = _dateOnly(now);

    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return List.generate(7, (index) {
      final day = startOfWeek.add(Duration(days: index));

      return sessionHistory.where((session) {
        return _isSameDay(session.completedAt, day);
      }).length;
    });
  }

  int get weeklyTotalMinutes {
    return weeklyFocusMinutes.fold<int>(0, (sum, minutes) => sum + minutes);
  }

  int get weeklyTotalSessions {
    return weeklySessionCounts.fold<int>(0, (sum, sessions) => sum + sessions);
  }

  // ===========================================================================
  // Copy With
  // ===========================================================================

  FocusState copyWith({
    int? selectedMinutes,
    int? remainingSeconds,
    FocusStatus? status,
    int? completedSessions,
    int? totalFocusMinutes,
    List<FocusSession>? sessionHistory,
  }) {
    return FocusState(
      selectedMinutes: selectedMinutes ?? this.selectedMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
      completedSessions: completedSessions ?? this.completedSessions,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      sessionHistory: sessionHistory ?? this.sessionHistory,
    );
  }

  // ===========================================================================
  // Private Helpers
  // ===========================================================================

  static DateTime _dateOnly(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

enum FocusStatus { ready, running, paused, completed }
