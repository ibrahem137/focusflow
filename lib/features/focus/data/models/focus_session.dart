class FocusSession {
  final String id;
  final int minutes;
  final DateTime completedAt;

  const FocusSession({
    required this.id,
    required this.minutes,
    required this.completedAt,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      minutes: json['minutes'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'minutes': minutes,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}
