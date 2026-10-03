import 'dart:async';
import 'dart:convert';

import 'reminder_service.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/focus/data/models/focus_session.dart';
import '../../features/focus/logic/focus_state.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/achievements/logic/achievement.dart';

/// A single versioned document makes reward + event updates indivisible.
/// Writes are serialized and published only after persistence succeeds.
class AppRepository {
  static const storageKey = 'focus_flow_v2';
  static const legacyKeys = [
    'tasks',
    'session_history',
    'total_xp',
    'selected_focus_minutes',
    'theme_mode',
    'completed_sessions',
    'total_focus_minutes',
  ];
  final ReminderService reminders;
  final Future<SharedPreferences> Function() preferences;
  AppRepository({
    Future<SharedPreferences> Function()? preferences,
    ReminderService? reminders,
  }) : reminders = reminders ?? ReminderService(),
       preferences = preferences ?? SharedPreferences.getInstance;
  final _changes = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  Stream<Map<String, dynamic>> get changes => _changes.stream;
  final error = ValueNotifier<String?>(null);
  Map<String, dynamic> data = defaults();
  Future<void>? _queue;
  bool _loaded = false;
  Future<void>? _loading;
  bool get loaded => _loaded;
  static Map<String, dynamic> defaults() => {
    'version': 2,
    'tasks': <dynamic>[],
    'sessions': <dynamic>[],
    'xp': 0,
    'completedTaskIds': <dynamic>[],
    'rewardIds': <dynamic>[],
    'achievements': <String, dynamic>{},
    'active': null,
    'selectedMinutes': 25,
    'settings': <String, dynamic>{
      'theme': 'system',
      'duration': 25,
      'sound': false,
      'haptics': true,
      'daily': false,
      'streak': false,
      'hour': 19,
      'minute': 0,
      'onboarded': false,
    },
  };
  List<TaskModel> get tasks => (data['tasks'] as List)
      .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  List<FocusSession> get sessions => (data['sessions'] as List)
      .map((e) => FocusSession.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  Map<String, dynamic> get settings =>
      Map<String, dynamic>.from(data['settings'] as Map);

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    final prefs = await preferences();
    final raw = prefs.getString(storageKey);
    late Map<String, dynamic> candidate;
    if (raw != null) {
      // Never overwrite unreadable data with a fresh document.
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      if (parsed['version'] != 2) {
        throw const FormatException('Unsupported candidate version');
      }
      candidate = {...defaults(), ...parsed};
      candidate['settings'] = {
        ...defaults()['settings'] as Map,
        ...parsed['settings'] as Map,
      };
      _validate(candidate); // Never overwrite unreadable saved records.
    } else {
      candidate = defaults();
      candidate['tasks'] = (prefs.getStringList('tasks') ?? [])
          .map(jsonDecode)
          .toList();
      candidate['sessions'] = (prefs.getStringList('session_history') ?? [])
          .map(jsonDecode)
          .toList();
      candidate['xp'] = prefs.getInt('total_xp') ?? 0;
      candidate['selectedMinutes'] =
          (prefs.getInt('selected_focus_minutes') ?? 25).clamp(1, 180);
      (candidate['settings'] as Map)['theme'] =
          prefs.getString('theme_mode') ?? 'system';
      (candidate['settings'] as Map)['duration'] = candidate['selectedMinutes'];
      final migratedTasks = (candidate['tasks'] as List)
          .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final migratedSessions = (candidate['sessions'] as List)
          .map(
            (e) => FocusSession.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      candidate['completedTaskIds'] = migratedTasks
          .where((t) => t.isCompleted || t.rewardClaimed)
          .map((t) => t.id)
          .toList();
      // Legacy rewards are already represented by legacy XP. Do not replay them.
      candidate['rewardIds'] = [
        ...migratedTasks
            .where((t) => t.rewardClaimed)
            .map((t) => 'task:${t.id}'),
        ...migratedSessions.map((s) => 'focus:${s.id}'),
      ];
      _validate(candidate);
      _evaluateAchievements(candidate);
      await _persist(prefs, candidate);
    }
    data = candidate;
    // A validated, durably stored v2 document must exist before cleanup.
    if (!await _removeLegacy(prefs)) {
      error.value = 'Your current data is safe, but some old local data could not be removed. Restart the app to retry, or use Reset all application data.';
    }
    _loaded = true;
    _changes.add(candidate);
  }

  void _validate(Map<String, dynamic> document) {
    if (document['version'] != 2 ||
        document['tasks'] is! List ||
        document['sessions'] is! List ||
        document['settings'] is! Map) {
      throw const FormatException('Invalid document');
    }
    final taskIds = <String>{};
    for (final task in (document['tasks'] as List).map(
      (e) => TaskModel.fromJson(Map<String, dynamic>.from(e as Map)),
    )) {
      if (task.id.isEmpty ||
          !taskIds.add(task.id) ||
          task.xp < 0 ||
          task.title.trim().isEmpty) {
        throw const FormatException('Invalid task record');
      }
    }
    final sessionIds = <String>{};
    for (final session in (document['sessions'] as List).map(
      (e) => FocusSession.fromJson(Map<String, dynamic>.from(e as Map)),
    )) {
      if (session.id.isEmpty ||
          !sessionIds.add(session.id) ||
          session.minutes < 1 ||
          session.minutes > 180) {
        throw const FormatException('Invalid focus record');
      }
    }
    if (document['xp'] is! int ||
        (document['xp'] as int) < 0 ||
        document['completedTaskIds'] is! List ||
        document['rewardIds'] is! List ||
        document['achievements'] is! Map) {
      throw const FormatException('Invalid progress');
    }
    if (document['selectedMinutes'] is! int ||
        (document['selectedMinutes'] as int) < 1 ||
        (document['selectedMinutes'] as int) > 180) {
      throw const FormatException('Invalid selected duration');
    }
    for (final key in ['completedTaskIds', 'rewardIds']) {
      final ids = document[key] as List;
      if (ids.any((id) => id is! String || id.trim().isEmpty) ||
          ids.toSet().length != ids.length) {
        throw FormatException('Invalid $key');
      }
    }
    final badgeIds = Achievement.all.map((badge) => badge.id).toSet();
    for (final entry in (document['achievements'] as Map).entries) {
      if (!badgeIds.contains(entry.key) ||
          entry.value is! String ||
          DateTime.tryParse(entry.value as String) == null) {
        throw const FormatException('Invalid achievement');
      }
    }
    final active = document['active'];
    if (active != null) {
      if (active is! Map ||
          active['id'] is! String ||
          (active['id'] as String).trim().isEmpty ||
          active['minutes'] is! int ||
          (active['minutes'] as int) < 1 ||
          (active['minutes'] as int) > 180 ||
          active['remaining'] is! int ||
          (active['remaining'] as int) < 0 ||
          (active['remaining'] as int) > (active['minutes'] as int) * 60 ||
          active['running'] is! bool ||
          (active['running'] == true &&
              DateTime.tryParse(active['endsAt']?.toString() ?? '') == null)) {
        throw const FormatException('Invalid active session');
      }
    }
    final settings = document['settings'] as Map;
    if (!['light', 'dark', 'system'].contains(settings['theme']) ||
        settings['duration'] is! int ||
        (settings['duration'] as int) < 1 ||
        (settings['duration'] as int) > 180 ||
        settings['hour'] is! int ||
        (settings['hour'] as int) < 0 ||
        (settings['hour'] as int) > 23 ||
        settings['minute'] is! int ||
        (settings['minute'] as int) < 0 ||
        (settings['minute'] as int) > 59) {
      throw const FormatException('Invalid settings');
    }
    for (final key in ['sound', 'haptics', 'daily', 'streak', 'onboarded']) {
      if (settings[key] is! bool) {
        throw const FormatException('Invalid setting');
      }
    }
  }

  Future<bool> update(
    void Function(Map<String, dynamic>) change, {
    bool evaluate = true,
  }) {
    final result = Completer<bool>();
    final operation = (_queue ?? Future<void>.value()).then((_) async {
      try {
        await load();
        final next = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
        change(next);
        _validate(next);
        if (evaluate) _evaluateAchievements(next);
        final prefs = await preferences();
        await _persist(prefs, next);
        data = next;
        error.value = null;
        _changes.add(data);
        result.complete(true);
      } catch (_) {
        error.value = 'Could not save your changes. Your previous data is safe. Please try again.';
        result.complete(false);
      }
    });
    _queue = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_queue, operation)) _queue = null;
      }),
    );
    return result.future;
  }

  Future<void> _persist(
    SharedPreferences prefs,
    Map<String, dynamic> document,
  ) async {
    try {
      if (!await prefs.setString(storageKey, jsonEncode(document))) {
        throw StateError('Local write failed');
      }
    } catch (_) {
      // SharedPreferences caches values before the platform accepts a write.
      // Failed migrations and updates must both discard speculative values.
      try {
        await prefs.reload();
      } catch (_) {
        /* Keep published state. */
      }
      rethrow;
    }
  }

  void _evaluateAchievements(Map<String, dynamic> next) {
    final history = (next['sessions'] as List)
        .map((e) => FocusSession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final focus = FocusState.initial().copyWith(sessionHistory: history);
    final metrics = {
      'sessions': history.length,
      'minutes': history.fold<int>(0, (sum, s) => sum + s.minutes),
      'tasks': (next['completedTaskIds'] as List).length,
      'streak': focus.bestStreak,
    };
    final unlocked = next['achievements'] as Map;
    for (final badge in Achievement.all) {
      if ((metrics[badge.metric] ?? 0) >= badge.target) {
        unlocked.putIfAbsent(badge.id, () => DateTime.now().toIso8601String());
      }
    }
  }

  /// Individual resets keep earned badges and reward tombstones: old events
  /// can never re-award XP. Only explicit full reset starts a fresh local state.
  Future<bool> reset(String scope) async {
    final saved = await update((d) {
      switch (scope) {
        case 'tasks':
          d['tasks'] = <dynamic>[];
          break;
        case 'focus':
          d['sessions'] = <dynamic>[];
          d['active'] = null;
          break;
        case 'progress':
          d['xp'] = 0;
          break;
        case 'all':
          d
            ..clear()
            ..addAll(defaults());
          break;
        default:
          throw ArgumentError.value(scope);
      }
    }, evaluate: false);
    if (saved && scope == 'all') {
      var cleaned = true;
      try {
        cleaned = await _removeLegacy(await preferences());
      } catch (_) {
        cleaned = false;
      }
      try {
        await reminders.clear();
      } catch (_) {
        cleaned = false;
      }
      if (!cleaned) {
        error.value = 'Current app data was reset, but some old local data or reminders could not be removed. Please retry Reset all application data.';
        return false;
      }
    }
    return saved;
  }

  Future<bool> _removeLegacy(SharedPreferences prefs) async {
    var cleaned = true;
    for (final key in legacyKeys) {
      try {
        if (prefs.containsKey(key) && !await prefs.remove(key)) cleaned = false;
      } catch (_) {
        cleaned = false;
      }
    }
    if (!cleaned) {
      // Failed plugin mutations can change the Dart cache before disk succeeds.
      try {
        await prefs.reload();
      } catch (_) {
        /* Preserve the cleanup warning. */
      }
    }
    return cleaned;
  }

  Future<void> flush() => _queue ?? Future<void>.value();
  Future<void> dispose() async {
    if (_loading != null) {
      try {
        await _loading;
      } catch (_) {
        /* Startup already reports this. */
      }
    }
    await flush();
    await _changes.close();
    error.dispose();
  }
}
