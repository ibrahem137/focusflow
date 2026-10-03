import 'dart:async';
import 'dart:convert';

import '../../../core/utils/event_id.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/app_repository.dart';
import '../data/models/task_model.dart';
import 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  final AppRepository repository;
  late final StreamSubscription<Map<String, dynamic>> _subscription;
  TasksCubit({AppRepository? repository})
    : repository = repository ?? AppRepository(),
      super(TasksState.initial()) {
    _subscription = this.repository.changes.listen((_) => _sync());
    if (this.repository.loaded) _sync();
  }
  String? _lastSnapshot;
  void _sync() {
    final snapshot = jsonEncode([
      repository.data['tasks'],
      repository.data['completedTaskIds'],
    ]);
    if (snapshot == _lastSnapshot) return;
    _lastSnapshot = snapshot;
    if (!isClosed) {
      emit(
        TasksState(
          tasks: repository.tasks,
          lifetimeCompletedTasks:
              (repository.data['completedTaskIds'] as List).length,
        ),
      );
    }
  }

  Future<void> loadTasks() async {
    await repository.load();
    _sync();
  }

  Future<bool> addTask({
    required String title,
    required String category,
    required int xp,
  }) async {
    if (title.trim().isEmpty ||
        category.trim().isEmpty ||
        xp <= 0 ||
        xp > 1000) {
      return false;
    }
    return repository.update((d) {
      final task = TaskModel(
        id: newEventId(),
        title: title.trim(),
        category: category.trim(),
        xp: xp,
      );
      (d['tasks'] as List).add(task.toJson());
    });
  }

  Future<bool> editTask(
    String id, {
    required String title,
    required String category,
  }) async {
    if (title.trim().isEmpty || category.trim().isEmpty) return false;
    var found = false;
    final saved = await repository.update((d) {
      for (final task in d['tasks'] as List) {
        if (task['id'] != id) continue;
        task['title'] = title.trim();
        task['category'] = category.trim();
        found = true;
      }
    });
    return saved && found;
  }

  Future<void> toggleTask(String id) async {
    await repository.update((d) {
      for (final t in d['tasks'] as List) {
        if (t['id'] != id) continue;
        t['isCompleted'] = !(t['isCompleted'] as bool);
        final completed = d['completedTaskIds'] as List;
        if (t['isCompleted'] == true && !completed.contains(id)) {
          completed.add(id);
        }
      }
    });
  }

  Future<bool> claimReward(String id) async {
    var claimed = false;
    final saved = await repository.update((d) {
      for (final t in d['tasks'] as List) {
        if (t['id'] != id ||
            t['isCompleted'] != true ||
            t['rewardClaimed'] == true) {
          continue;
        }
        final rewards = d['rewardIds'] as List;
        if (rewards.contains('task:$id')) continue;
        rewards.add('task:$id');
        t['rewardClaimed'] = true;
        d['xp'] = (d['xp'] as int) + (t['xp'] as int);
        claimed = true;
      }
    });
    return saved && claimed;
  }

  Future<void> deleteTask(String id) async {
    await repository.update(
      (d) => (d['tasks'] as List).removeWhere((t) => t['id'] == id),
    );
  }

  TaskModel? getTaskById(String id) {
    for (final t in state.tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await repository.flush();
    return super.close();
  }
}
