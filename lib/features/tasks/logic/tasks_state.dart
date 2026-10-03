import '../data/models/task_model.dart';

class TasksState {
  final List<TaskModel> tasks;
  final int lifetimeCompletedTasks;

  const TasksState({required this.tasks, this.lifetimeCompletedTasks = 0});

  factory TasksState.initial() => const TasksState(tasks: []);

  int get completedTasks {
    return tasks.where((task) => task.isCompleted).length;
  }

  double get completionProgress {
    if (tasks.isEmpty) {
      return 0;
    }

    return completedTasks / totalTasks;
  }

  int get remainingTasks {
    return tasks.where((task) => !task.isCompleted).length;
  }

  int get totalTasks => tasks.length;

  TasksState copyWith({List<TaskModel>? tasks}) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      lifetimeCompletedTasks: lifetimeCompletedTasks,
    );
  }
}
