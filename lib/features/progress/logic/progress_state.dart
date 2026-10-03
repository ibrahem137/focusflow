class ProgressState {
  final int totalXp;

  const ProgressState({required this.totalXp});

  factory ProgressState.initial() {
    return const ProgressState(totalXp: 0);
  }

  int get currentLevelXp {
    return totalXp % 1000;
  }

  int get level {
    return (totalXp ~/ 1000) + 1;
  }

  double get levelProgress {
    return currentLevelXp / xpForNextLevel;
  }

  int get remainingXp {
    return xpForNextLevel - currentLevelXp;
  }

  int get xpForNextLevel {
    return 1000;
  }

  ProgressState copyWith({int? totalXp}) {
    return ProgressState(totalXp: totalXp ?? this.totalXp);
  }
}
