import 'package:focus_flow/core/widgets/app_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/core/constants/theme/app_colors.dart';
import 'package:focus_flow/core/constants/theme/logic/theme_cubit.dart';
import 'package:focus_flow/core/constants/theme/logic/theme_state.dart';
import 'package:focus_flow/features/focus/logic/focus_cubit.dart';
import 'package:focus_flow/features/focus/logic/focus_state.dart';
import 'package:focus_flow/features/progress/logic/progress_cubit.dart';
import 'package:focus_flow/features/progress/logic/progress_state.dart';
import 'package:focus_flow/features/tasks/data/models/task_model.dart';
import 'package:focus_flow/features/tasks/logic/tasks_cubit.dart';
import 'package:focus_flow/features/tasks/logic/tasks_state.dart';

// =============================================================================

// Level Up Dialog

// =============================================================================

class HomeScreen extends StatefulWidget {
  final bool isActive;

  final VoidCallback onStartFocus;

  final VoidCallback onSeeAllTasks;

  const HomeScreen({
    super.key,

    required this.isActive,

    required this.onStartFocus,

    required this.onSeeAllTasks,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// =============================================================================

// Start Focus Press Animation

// =============================================================================

class _AnimatedPressButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedPressButton({required this.onPressed});

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _setPressed(true);
      },

      onTapCancel: () {
        _setPressed(false);
      },

      onTapUp: (_) {
        _setPressed(false);

        widget.onPressed();
      },

      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,

        duration: const Duration(milliseconds: 120),

        curve: Curves.easeOutCubic,

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          curve: Curves.easeOutCubic,

          width: double.infinity,

          height: 52,

          decoration: BoxDecoration(
            color: AppColors.primary,

            borderRadius: BorderRadius.circular(16),

            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: _pressed ? 0.18 : 0.30,
                ),

                blurRadius: _pressed ? 10 : 20,

                offset: Offset(0, _pressed ? 3 : 7),
              ),
            ],
          ),

          alignment: Alignment.center,

          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white),

              SizedBox(width: 8),

              Flexible(
                child: Text(
                  'Start Focus',

                  style: TextStyle(
                    color: Colors.white,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }
}

// =============================================================================

// Staggered Entrance Animation

// =============================================================================

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceController;

  late final AnimationController _focusPulseController;

  late final Animation<double> _focusPulse;

  late final Animation<double> _focusGlow;

  // ===========================================================================

  // Build

  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // Header

            AppEntrance(
              controller: _entranceController,

              begin: 0.00,

              end: 0.35,

              child: _buildHeader(context),
            ),

            const SizedBox(height: 28),

            // Level
            AppEntrance(
              controller: _entranceController,

              begin: 0.10,

              end: 0.48,

              child: BlocBuilder<ProgressCubit, ProgressState>(
                builder: (context, state) {
                  return _buildLevelCard(context, state);
                },
              ),
            ),

            const SizedBox(height: 20),

            // Focus
            AppEntrance(
              controller: _entranceController,

              begin: 0.20,

              end: 0.60,

              child: _buildFocusCard(context),
            ),

            const SizedBox(height: 28),

            // Tasks title
            AppEntrance(
              controller: _entranceController,

              begin: 0.32,

              end: 0.68,

              child: _buildTasksHeader(context),
            ),

            const SizedBox(height: 14),

            // Tasks
            BlocBuilder<TasksCubit, TasksState>(
              builder: (context, tasksState) {
                final tasks = tasksState.tasks.take(3).toList();

                if (tasks.isEmpty) {
                  return AppEntrance(
                    controller: _entranceController,

                    begin: 0.45,

                    end: 0.85,

                    child: _buildEmptyTasks(context),
                  );
                }

                return Column(
                  children: List.generate(tasks.length, (index) {
                    final task = tasks[index];

                    final begin = 0.42 + (index * 0.08);

                    final end = 0.76 + (index * 0.08);

                    return AppEntrance(
                      controller: _entranceController,

                      begin: begin.clamp(0.0, 0.85),

                      end: end.clamp(0.15, 1.0),

                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),

                        child: _buildHomeTaskCard(context, task),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _focusPulseController.stop();
    } else if (!_focusPulseController.isAnimating) {
      _focusPulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _replayEntranceAnimation();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();

    _focusPulseController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // -------------------------------------------------------------------------

    // Page entrance

    // -------------------------------------------------------------------------

    _entranceController = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 1100),
    );

    // -------------------------------------------------------------------------

    // Focus breathing animation

    // -------------------------------------------------------------------------

    _focusPulseController = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 1800),
    );

    _focusPulse = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _focusPulseController, curve: Curves.easeInOut),
    );

    _focusGlow = Tween<double>(begin: 0.12, end: 0.30).animate(
      CurvedAnimation(parent: _focusPulseController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _entranceController.forward();
    }

    _focusPulseController.repeat(reverse: true);
  }

  // ===========================================================================

  // Empty Tasks

  // ===========================================================================

  Widget _buildEmptyTasks(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),

      decoration: BoxDecoration(
        color: colors.surface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: colors.outlineVariant),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.task_alt_rounded,

            color: AppColors.secondary,

            size: 28,
          ),

          const SizedBox(height: 8),

          Text(
            'No tasks for today',

            style: TextStyle(
              color: colors.onSurface,

              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Add a task and keep moving forward.',

            textAlign: TextAlign.center,

            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ===========================================================================

  // Focus Card

  // ===========================================================================

  Widget _buildFocusCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),

        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.14),

            AppColors.secondary.withValues(alpha: isDark ? 0.08 : 0.055),
          ],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,
        ),

        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.18),
        ),
      ),

      child: Column(
        children: [
          AnimatedBuilder(
            animation: _focusPulseController,

            builder: (context, child) {
              return Transform.scale(
                scale: _focusPulse.value,

                child: Container(
                  width: 68,

                  height: 68,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.18 : 0.12,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: _focusGlow.value,
                        ),

                        blurRadius: 28,

                        spreadRadius: 2,
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons.timer_rounded,

                    color: AppColors.primary,

                    size: 32,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          Text(
            'Ready to focus?',

            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 7),

          Text(
            'Build your garden one session at a time.',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,

              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          _AnimatedPressButton(onPressed: widget.onStartFocus),
        ],
      ),
    );
  }

  // ===========================================================================

  // Header

  // ===========================================================================

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                _greeting(),

                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 6),

              Text(
                'Ready to make today count?',

                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Theme Toggle
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return Tooltip(
              message: Theme.of(context).brightness == Brightness.dark
                  ? 'Switch to light mode'
                  : 'Switch to dark mode',

              child: Material(
                color: Colors.transparent,

                child: InkWell(
                  onTap: () {
                    context.read<ThemeCubit>().setTheme(
                      Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    );
                  },

                  borderRadius: BorderRadius.circular(14),

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),

                    curve: Curves.easeOutCubic,

                    width: 40,

                    height: 40,

                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,

                      borderRadius: BorderRadius.circular(14),

                      border: Border.all(color: colors.outlineVariant),
                    ),

                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),

                      switchInCurve: Curves.easeOutCubic,

                      switchOutCurve: Curves.easeInCubic,

                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: Tween<double>(
                            begin: 0.75,

                            end: 1,
                          ).animate(animation),

                          child: ScaleTransition(
                            scale: animation,

                            child: child,
                          ),
                        );
                      },

                      child: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,

                        key: ValueKey(
                          Theme.of(context).brightness == Brightness.dark,
                        ),

                        size: 20,

                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 8),

        // Real Streak
        BlocBuilder<FocusCubit, FocusState>(
          buildWhen: (previous, current) {
            return previous.currentStreak != current.currentStreak;
          },

          builder: (context, focusState) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),

              curve: Curves.easeOutCubic,

              height: 40,

              padding: const EdgeInsets.symmetric(horizontal: 11),

              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),

                borderRadius: BorderRadius.circular(14),

                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.12),
                ),
              ),

              child: Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),

                  const SizedBox(width: 5),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),

                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,

                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },

                    child: Text(
                      '${focusState.currentStreak}',

                      key: ValueKey(focusState.currentStreak),

                      style: const TextStyle(
                        color: AppColors.warning,

                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================

  // Home Task Card

  // ===========================================================================

  Widget _buildHomeTaskCard(BuildContext context, TaskModel task) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),

      curve: Curves.easeOutCubic,

      opacity: task.isCompleted ? 0.58 : 1,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),

        curve: Curves.easeOutCubic,

        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

        decoration: BoxDecoration(
          color: colors.surface,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: task.isCompleted
                ? AppColors.secondary.withValues(alpha: 0.25)
                : colors.outlineVariant,
          ),
        ),

        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),

              curve: Curves.easeOutCubic,

              width: 40,

              height: 40,

              decoration: BoxDecoration(
                color: task.isCompleted
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.12),

                borderRadius: BorderRadius.circular(12),
              ),

              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),

                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,

                    child: FadeTransition(opacity: animation, child: child),
                  );
                },

                child: Icon(
                  task.isCompleted
                      ? Icons.check_rounded
                      : _taskIcon(task.category),

                  key: ValueKey(task.isCompleted),

                  color: task.isCompleted
                      ? AppColors.secondary
                      : AppColors.primary,

                  size: 21,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),

                curve: Curves.easeOutCubic,

                style: TextStyle(
                  color: task.isCompleted
                      ? colors.onSurfaceVariant
                      : colors.onSurface,

                  fontSize: 13,

                  fontWeight: FontWeight.w600,

                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,

                  decorationColor: colors.onSurfaceVariant,
                ),

                child: Text(
                  task.title,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            const SizedBox(width: 8),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),

              curve: Curves.easeOutCubic,

              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

              decoration: BoxDecoration(
                color: task.isCompleted
                    ? AppColors.secondary.withValues(alpha: 0.10)
                    : AppColors.primary.withValues(alpha: 0.10),

                borderRadius: BorderRadius.circular(20),
              ),

              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),

                child: Text(
                  task.isCompleted ? 'Done' : '+${task.xp} XP',

                  key: ValueKey(task.isCompleted),

                  style: TextStyle(
                    color: task.isCompleted
                        ? AppColors.secondary
                        : AppColors.primary,

                    fontSize: 10,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================

  // Level Card

  // ===========================================================================

  Widget _buildLevelCard(BuildContext context, ProgressState state) {
    final colors = Theme.of(context).colorScheme;

    final progress = state.levelProgress.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: colors.surface,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: colors.outlineVariant),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.08
                  : 0.035,
            ),

            blurRadius: 20,

            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.90, end: 1),

                duration: const Duration(milliseconds: 600),

                curve: Curves.easeOutBack,

                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },

                child: Container(
                  width: 48,

                  height: 48,

                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),

                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: const Icon(
                    Icons.bolt_rounded,

                    color: AppColors.primary,

                    size: 28,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'LEVEL ${state.level}',

                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: AppColors.primary),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Keep going, you are doing great!',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,

                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),

                duration: const Duration(milliseconds: 900),

                curve: Curves.easeOutCubic,

                builder: (context, value, child) {
                  return Text(
                    '${(value * 100).round()}%',

                    style: TextStyle(
                      fontWeight: FontWeight.w700,

                      color: colors.onSurface,
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
              tween: Tween<double>(begin: 0, end: progress),

              duration: const Duration(milliseconds: 1000),

              curve: Curves.easeOutCubic,

              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,

                  minHeight: 8,

                  backgroundColor: colors.surfaceContainerHighest,

                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 9),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                '${state.currentLevelXp} XP',

                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),

              Text(
                '${state.xpForNextLevel} XP',

                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================

  // Tasks Header

  // ===========================================================================

  Widget _buildTasksHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Today\'s Tasks',

            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),

        TextButton(
          onPressed: widget.onSeeAllTasks,

          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,

            minimumSize: Size.zero,

            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),

          child: const Text(
            'See all',

            style: TextStyle(
              color: AppColors.primary,

              fontSize: 12,

              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================

  // Greeting

  // ===========================================================================

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning 👋';
    }

    if (hour < 18) {
      return 'Good afternoon 👋';
    }

    return 'Good evening 👋';
  }

  void _replayEntranceAnimation() {
    _entranceController
      ..stop()
      ..reset()
      ..forward();
  }

  // ===========================================================================

  // Task Icon

  // ===========================================================================

  IconData _taskIcon(String category) {
    switch (category) {
      case 'Learning':
        return Icons.school_rounded;

      case 'Work':
        return Icons.code_rounded;

      case 'Personal':
        return Icons.person_rounded;

      default:
        return Icons.task_alt_rounded;
    }
  }
}
