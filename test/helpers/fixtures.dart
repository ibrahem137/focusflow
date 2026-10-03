import 'dart:convert';

Map<String, Object> legacyTaskFixture() => {
  'tasks': [
    for (final item in [
      ('1', 'Study Laravel', 'Learning', 50),
      ('2', 'Work on FocusFlow', 'Work', 40),
      ('3', 'Read 20 minutes', 'Personal', 20),
    ])
      jsonEncode({
        'id': item.$1,
        'title': item.$2,
        'category': item.$3,
        'xp': item.$4,
        'isCompleted': false,
        'rewardClaimed': false,
      }),
  ],
};
