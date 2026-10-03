import '../widgets/add_task_dialog.dart';

import 'package:focus_flow/core/widgets/app_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/core/constants/theme/app_colors.dart';
import 'package:focus_flow/features/tasks/data/models/task_model.dart';
import 'package:focus_flow/features/tasks/logic/tasks_cubit.dart';
import 'package:focus_flow/features/tasks/logic/tasks_state.dart';

class TasksScreen extends StatefulWidget {
  final bool isActive;
  const TasksScreen({this.isActive = false, super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

// =============================================================================
// Add Task Dialog
// =============================================================================

// =============================================================================
// Category Chip
// =============================================================================

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final secondaryText = theme.colorScheme.onSurfaceVariant;

    final background = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF5F3FF);

    IconData icon;

    switch (category) {
      case 'Learning':
        icon = Icons.school_rounded;
        break;

      case 'Work':
        icon = Icons.code_rounded;
        break;

      default:
        icon = Icons.person_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: secondaryText),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              category,
              style: TextStyle(
                color: secondaryText,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Entrance Animation
// =============================================================================

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.00,
                  end: 0.30,
                  child: _buildHeader(context),
                ),
                const SizedBox(height: 24),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.07,
                  end: 0.38,
                  child: _buildProgressCard(context, state),
                ),
                const SizedBox(height: 28),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.15,
                  end: 0.46,
                  child: _buildTasksHeader(context, state),
                ),
                const SizedBox(height: 14),

                if (state.tasks.isEmpty)
                  AppEntrance(
                    controller: _entranceController,
                    begin: 0.25,
                    end: 0.60,
                    child: _buildEmptyState(context),
                  )
                else
                  ...List.generate(state.tasks.length, (index) {
                    final task = state.tasks[index];

                    final begin = (0.22 + (index * 0.055)).clamp(0.0, 0.80);
                    final end = (0.55 + (index * 0.055)).clamp(0.20, 1.0);

                    return AppEntrance(
                      controller: _entranceController,
                      begin: begin,
                      end: end,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTaskCard(context, task),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // انتقل المستخدم من شاشة أخرى إلى Tasks.
    if (!oldWidget.isActive && widget.isActive) {
      _playEntranceAnimation();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // لا نشغل Animation إلا إذا كانت Tasks هي الشاشة الظاهرة.
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _playEntranceAnimation();
      });
    }
  }

  // ===========================================================================
  // Colors
  // ===========================================================================

  Color _borderColor(BuildContext context) {
    final theme = Theme.of(context);

    return theme.colorScheme.outlineVariant;
  }

  // ===========================================================================
  // Empty State
  // ===========================================================================

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 14),
          Text(
            'No tasks yet',
            style: TextStyle(
              color: _primaryText(context),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a task and make today count.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText(context), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Header
  // ===========================================================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Tasks',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                'Small steps. Big progress.',
                style: TextStyle(color: _secondaryText(context), fontSize: 13),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 46,
          height: 46,
          child: FilledButton(
            onPressed: () {
              _showAddTaskDialog(context);
            },
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Icon(Icons.add_rounded, size: 26),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Progress Card
  // ===========================================================================

  Widget _buildProgressCard(BuildContext context, TasksState state) {
    final percentage = (state.completionProgress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        color: _primaryText(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.completedTasks} of '
                      '${state.totalTasks} tasks completed',
                      style: TextStyle(
                        color: _secondaryText(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percentage.toDouble()),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    '${value.round()}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: state.completionProgress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: _softSurface(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Task Card
  // ===========================================================================

  Widget _buildTaskCard(BuildContext context, TaskModel task) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      opacity: task.isCompleted && task.rewardClaimed ? 0.85 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? AppColors.secondary.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.06
                      : 0.04,
                )
              : _cardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: task.isCompleted
                ? AppColors.secondary.withValues(alpha: 0.30)
                : _borderColor(context),
          ),
        ),
        child: Row(
          children: [
            Semantics(
              label: 'Complete ${task.title}',
              checked: task.isCompleted,
              child: GestureDetector(
                key: ValueKey('toggle-${task.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _toggleTask(context, task);
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('${task.id}-${task.isCompleted}'),
                    tween: Tween<double>(
                      begin: task.isCompleted ? 0.65 : 0.90,
                      end: 1,
                    ),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isCompleted
                            ? AppColors.secondary
                            : Colors.transparent,
                        border: Border.all(
                          color: task.isCompleted
                              ? AppColors.secondary
                              : _secondaryText(context),
                          width: 2,
                        ),
                        boxShadow: task.isCompleted
                            ? [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: task.isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                key: ValueKey('checked'),
                                size: 18,
                                color: Colors.white,
                              )
                            : const SizedBox(key: ValueKey('unchecked')),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      color: _primaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _CategoryChip(category: task.category),
                      if (task.isCompleted && !task.rewardClaimed)
                        TextButton.icon(
                          onPressed: () => _claimReward(context, task),
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text('Claim XP'),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            task.rewardClaimed ? 'XP earned' : '+${task.xp} XP',
                            key: ValueKey(task.rewardClaimed),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit task',
                  onPressed: () => _editTask(context, task),
                  icon: Icon(
                    Icons.edit_outlined,
                    color: _secondaryText(context),
                    size: 21,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete task',
                  onPressed: () => _confirmDelete(context, task),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: _secondaryText(context),
                    size: 21,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Tasks Header
  // ===========================================================================

  Widget _buildTasksHeader(BuildContext context, TasksState state) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text('Today', style: Theme.of(context).textTheme.titleLarge),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            '${state.remainingTasks} remaining',
            key: ValueKey(state.remainingTasks),
            style: TextStyle(color: _secondaryText(context), fontSize: 11),
          ),
        ),
      ],
    );
  }

  Color _cardColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  // ===========================================================================
  // Delete
  // ===========================================================================

  void _editTask(BuildContext context, TaskModel task) {
    final tasks = context.read<TasksCubit>();
    showDialog<void>(
      context: context,
      builder: (_) => AddTaskDialog(
        task: task,
        onAddTask: ({required title, required category, required xp}) =>
            tasks.editTask(task.id, title: title, category: category),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TaskModel task) {
    final tasksCubit = context.read<TasksCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Delete task?',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${task.title}"?',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () {
                tasksCubit.deleteTask(task.id);
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _playEntranceAnimation() {
    if (!mounted) {
      return;
    }

    _entranceController.forward(from: 0);
  }

  Color _primaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _secondaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  // ===========================================================================
  // Add Task
  // ===========================================================================

  void _showAddTaskDialog(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AddTaskDialog(
          onAddTask:
              ({
                required String title,
                required String category,
                required int xp,
              }) {
                return tasksCubit.addTask(
                  title: title,
                  category: category,
                  xp: xp,
                );
              },
        );
      },
    );
  }

  // ===========================================================================
  // XP Snackbar
  // ===========================================================================

  void _showXpSnackBar(BuildContext context, int xp) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Task completed! +$xp XP',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
  }

  Color _softSurface(BuildContext context) {
    final theme = Theme.of(context);

    return theme.colorScheme.surfaceContainerHighest;
  }

  // ===========================================================================
  // Toggle + XP
  // ===========================================================================

  Future<void> _toggleTask(BuildContext context, TaskModel task) async {
    await context.read<TasksCubit>().toggleTask(task.id);
  }

  Future<void> _claimReward(BuildContext context, TaskModel task) async {
    final claimed = await context.read<TasksCubit>().claimReward(task.id);
    if (claimed && context.mounted) _showXpSnackBar(context, task.xp);
  }
}
