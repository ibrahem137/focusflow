import '../widgets/stats_painters.dart';

import 'package:focus_flow/core/widgets/app_entrance.dart';

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/core/constants/theme/app_colors.dart';
import 'package:focus_flow/features/focus/logic/focus_cubit.dart';
import 'package:focus_flow/features/focus/logic/focus_state.dart';
import 'package:focus_flow/features/progress/logic/progress_cubit.dart';
import 'package:focus_flow/features/progress/logic/progress_state.dart';
import 'package:focus_flow/features/tasks/logic/tasks_cubit.dart';
import 'package:focus_flow/features/tasks/logic/tasks_state.dart';

class StatsScreen extends StatefulWidget {
  final bool isActive;

  const StatsScreen({super.key, required this.isActive});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _AnimatedIconBox extends StatelessWidget {
  final IconData icon;
  final AnimationController lifeController;

  const _AnimatedIconBox({required this.icon, required this.lifeController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lifeController,
      builder: (context, child) {
        final pulse = 1 + math.sin(lifeController.value * math.pi * 2) * 0.035;

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
        );
      },
    );
  }
}

class _AnimatedStatCard extends StatefulWidget {
  final IconData icon;
  final int numericValue;
  final String displayValue;
  final String label;
  final double delay;
  final AnimationController lifeController;

  const _AnimatedStatCard({
    required this.icon,
    required this.numericValue,
    required this.displayValue,
    required this.label,
    required this.delay,
    required this.lifeController,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final borderColor = theme.brightness == Brightness.dark
        ? colors.outlineVariant
        : const Color(0xFFE1E1E8);

    return AnimatedBuilder(
      animation: widget.lifeController,
      builder: (context, child) {
        final phase = (widget.lifeController.value + widget.delay) % 1.0;
        final iconOffset = math.sin(phase * math.pi * 2) * 1.4;

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: Offset(0, iconOffset),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      widget.displayValue,
                      key: ValueKey('${widget.label}-${widget.numericValue}'),
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Small widgets
// =============================================================================

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 12),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Productivity ring
// =============================================================================

// =============================================================================
// Score painter
// =============================================================================

// =============================================================================
// Entrance animation
// =============================================================================

class _StatsScreenState extends State<StatsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _lifeController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppEntrance(
              controller: _entranceController,
              begin: 0.00,
              end: 0.30,
              child: _buildHeader(context),
            ),
            const SizedBox(height: 26),
            BlocBuilder<FocusCubit, FocusState>(
              builder: (context, focusState) {
                return BlocBuilder<TasksCubit, TasksState>(
                  builder: (context, tasksState) {
                    return BlocBuilder<ProgressCubit, ProgressState>(
                      builder: (context, progressState) {
                        return Column(
                          children: [
                            AppEntrance(
                              controller: _entranceController,
                              begin: 0.08,
                              end: 0.46,
                              child: _buildHeroInsight(
                                context,
                                focusState,
                                tasksState,
                                progressState,
                              ),
                            ),

                            if (focusState.sessionHistory.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'Complete your first focus session to start seeing insights.',
                                ),
                              ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: const Text('Best streak'),
                                      trailing: Text(
                                        '${focusState.bestStreak} days',
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text('Average session'),
                                      trailing: Text(
                                        '${focusState.averageSessionMinutes.toStringAsFixed(1)} min',
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text('Daily average'),
                                      subtitle: const Text(
                                        'Calendar days since your first session',
                                      ),
                                      trailing: Text(
                                        '${focusState.averageDailyMinutes.toStringAsFixed(1)} min',
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text('Most productive day'),
                                      subtitle: Text(
                                        focusState.mostProductiveDay,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),
                            AppEntrance(
                              controller: _entranceController,
                              begin: 0.20,
                              end: 0.56,
                              child: _buildOverview(
                                context,
                                focusState,
                                tasksState,
                                progressState,
                              ),
                            ),
                            const SizedBox(height: 22),
                            AppEntrance(
                              controller: _entranceController,
                              begin: 0.34,
                              end: 0.70,
                              child: _buildWeeklyFocusChart(
                                context,
                                focusState,
                              ),
                            ),
                            const SizedBox(height: 20),
                            AppEntrance(
                              controller: _entranceController,
                              begin: 0.48,
                              end: 0.84,
                              child: _buildProductivityCard(
                                context,
                                tasksState,
                              ),
                            ),
                            const SizedBox(height: 20),
                            AppEntrance(
                              controller: _entranceController,
                              begin: 0.62,
                              end: 1.00,
                              child: _buildLevelCard(context, progressState),
                            ),
                          ],
                        );
                      },
                    );
                  },
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
      _lifeController.stop();
    } else if (!_lifeController.isAnimating) {
      _lifeController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _entranceController
        ..stop()
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _lifeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );

    _lifeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    if (widget.isActive) {
      _entranceController.forward();
    }
  }

  Color _borderColor(BuildContext context) {
    final theme = Theme.of(context);

    return theme.brightness == Brightness.dark
        ? theme.colorScheme.outlineVariant
        : const Color(0xFFE1E1E8);
  }

  // ===========================================================================
  // Header
  // ===========================================================================

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics 📊',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          'See how far your focus has taken you.',
          style: TextStyle(color: _secondaryText(context), fontSize: 13),
        ),
      ],
    );
  }

  // ===========================================================================
  // Hero / living insight
  // ===========================================================================

  Widget _buildHeroInsight(
    BuildContext context,
    FocusState focusState,
    TasksState tasksState,
    ProgressState progressState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeklyMinutes = focusState.weeklyFocusMinutes;
    final weeklyTotal = weeklyMinutes.fold<int>(0, (sum, value) => sum + value);

    final score = _performanceScore(
      weeklyMinutes: weeklyTotal,
      completionProgress: tasksState.completionProgress,
      streak: focusState.currentStreak,
    );

    final message = _performanceMessage(score);

    return AnimatedBuilder(
      animation: _lifeController,
      builder: (context, _) {
        final wave = _lifeController.value;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                AppColors.secondary.withValues(alpha: isDark ? 0.10 : 0.06),
                Theme.of(context).colorScheme.surface,
              ],
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.24 : 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.09 : 0.05,
                ),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: CustomPaint(
                  painter: PulseScorePainter(
                    progress: score / 100,
                    lifeProgress: wave,
                    isDark: isDark,
                  ),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: score.toDouble()),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${value.round()}',
                              style: TextStyle(
                                color: _primaryText(context),
                                fontSize: 28,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SCORE',
                              style: TextStyle(
                                color: _secondaryText(context),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'LIVE PERFORMANCE',
                            style: TextStyle(
                              color: _secondaryText(context),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message.$1,
                      style: TextStyle(
                        color: _primaryText(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message.$2,
                      style: TextStyle(
                        color: _secondaryText(context),
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _MiniPill(
                          icon: Icons.local_fire_department_rounded,
                          text: '${focusState.currentStreak} day streak',
                        ),
                        _MiniPill(
                          icon: Icons.stars_rounded,
                          text: 'Lv. ${progressState.level}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Level
  // ===========================================================================

  Widget _buildLevelCard(BuildContext context, ProgressState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _lifeController,
      builder: (context, child) {
        final pulse = 1 + math.sin(_lifeController.value * math.pi * 2) * 0.035;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderColor(context)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.22),
                            AppColors.secondary.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.16 : 0.10,
                            ),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.primary,
                        size: 27,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Text(
                            'Level ${state.level}',
                            key: ValueKey(state.level),
                            style: TextStyle(
                              color: _primaryText(context),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.remainingXp} XP to next level',
                          style: TextStyle(
                            color: _secondaryText(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: state.levelProgress * 100,
                    ),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        '${value.round()}%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(height: 9, color: _softSurface(context)),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: state.levelProgress),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.30,
                                ),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.currentLevelXp} XP',
                    style: TextStyle(
                      color: _secondaryText(context),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${state.xpForNextLevel} XP',
                    style: TextStyle(
                      color: _secondaryText(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Overview
  // ===========================================================================

  Widget _buildOverview(
    BuildContext context,
    FocusState focusState,
    TasksState tasksState,
    ProgressState progressState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            color: _primaryText(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AnimatedStatCard(
                icon: Icons.timer_rounded,
                numericValue: focusState.totalFocusMinutes,
                displayValue: _formatFocusTime(focusState.totalFocusMinutes),
                label: 'Focus Time',
                delay: 0.00,
                lifeController: _lifeController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatCard(
                icon: Icons.bolt_rounded,
                numericValue: focusState.completedSessions,
                displayValue: '${focusState.completedSessions}',
                label: 'Sessions',
                delay: 0.15,
                lifeController: _lifeController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AnimatedStatCard(
                icon: Icons.task_alt_rounded,
                numericValue: tasksState.lifetimeCompletedTasks,
                displayValue: '${tasksState.lifetimeCompletedTasks}',
                label: 'Lifetime Tasks',
                delay: 0.30,
                lifeController: _lifeController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatCard(
                icon: Icons.stars_rounded,
                numericValue: progressState.totalXp,
                displayValue: '${progressState.totalXp}',
                label: 'Total XP',
                delay: 0.45,
                lifeController: _lifeController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // Productivity
  // ===========================================================================

  Widget _buildProductivityCard(BuildContext context, TasksState state) {
    final percentage = (state.completionProgress * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 102,
            height: 102,
            child: AnimatedBuilder(
              animation: _lifeController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ProductivityRingPainter(
                    progress: state.completionProgress,
                    lifeProgress: _lifeController.value,
                    isDark: isDark,
                  ),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: percentage.toDouble(),
                      ),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          '${value.round()}%',
                          style: TextStyle(
                            color: _primaryText(context),
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Productivity',
                        style: TextStyle(
                          color: _primaryText(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  _productivityMessage(percentage),
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${state.completedTasks} of '
                  '${state.totalTasks} tasks completed',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Weekly Focus Chart
  // ===========================================================================

  Widget _buildWeeklyFocusChart(BuildContext context, FocusState state) {
    final weeklyData = state.weeklyFocusMinutes;
    final totalWeekMinutes = weeklyData.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    final highestMinutes = weeklyData.fold<int>(
      0,
      (highest, value) => value > highest ? value : highest,
    );

    final maxY = highestMinutes == 0
        ? 60.0
        : (highestMinutes * 1.25).ceilToDouble();

    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AnimatedIconBox(
                icon: Icons.bar_chart_rounded,
                lifeController: _lifeController,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Focus',
                      style: TextStyle(
                        color: _primaryText(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Your focus rhythm this week',
                      style: TextStyle(
                        color: _secondaryText(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      _formatFocusTime(totalWeekMinutes),
                      key: ValueKey(totalWeekMinutes),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'this week',
                    style: TextStyle(
                      color: _secondaryText(context),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 3,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: _borderColor(context), strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= dayNames.length) {
                          return const SizedBox.shrink();
                        }

                        final isToday = index == todayIndex;

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: isToday
                                ? const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  )
                                : EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.primary.withValues(alpha: 0.10)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dayNames[index],
                              style: TextStyle(
                                color: isToday
                                    ? AppColors.primary
                                    : _secondaryText(context),
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(10),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final minutes = weeklyData[group.x];

                      return BarTooltipItem(
                        _formatFocusTime(minutes),
                        TextStyle(
                          color: isDark ? Colors.white : _primaryText(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  final minutes = weeklyData[index].toDouble();
                  final isToday = index == todayIndex;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: minutes,
                        width: 17,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isToday
                              ? [AppColors.primary, AppColors.secondary]
                              : [
                                  AppColors.primary.withValues(alpha: 0.45),
                                  AppColors.secondary.withValues(alpha: 0.70),
                                ],
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: _softSurface(context),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 13,
                color: _secondaryText(context),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Tap a bar · minutes',
                  style: TextStyle(color: _secondaryText(context), fontSize: 9),
                ),
              ),
              const Spacer(),
              if (totalWeekMinutes > 0)
                const Text(
                  'Keep it going 🔥',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFocusTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}m';
  }

  (String, String) _performanceMessage(int score) {
    if (score >= 85) {
      return (
        'You\'re on fire 🔥',
        'Your focus rhythm is exceptionally strong. Keep protecting it.',
      );
    }

    if (score >= 65) {
      return (
        'Great momentum ✨',
        'You\'re building a strong rhythm. A little more consistency will push you higher.',
      );
    }

    if (score >= 40) {
      return (
        'Momentum is growing 🌱',
        'Every focused session is moving you forward. Keep stacking small wins.',
      );
    }

    return (
      'A fresh start 🚀',
      'Your next focused session can change today\'s direction. Start small and build.',
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  int _performanceScore({
    required int weeklyMinutes,
    required double completionProgress,
    required int streak,
  }) {
    final focusScore = (weeklyMinutes / 300).clamp(0.0, 1.0) * 45;
    final taskScore = completionProgress.clamp(0.0, 1.0) * 35;
    final streakScore = (streak / 7).clamp(0.0, 1.0) * 20;

    return (focusScore + taskScore + streakScore).round();
  }

  Color _primaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  String _productivityMessage(int percentage) {
    if (percentage >= 100) {
      return 'Everything is done. Outstanding work today!';
    }

    if (percentage >= 75) {
      return 'Almost there. Finish strong and close the day.';
    }

    if (percentage >= 40) {
      return 'Good progress. Keep the momentum moving.';
    }

    return 'A few focused wins can turn the day around.';
  }

  Color _secondaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Color _softSurface(BuildContext context) {
    final theme = Theme.of(context);

    return theme.colorScheme.surfaceContainerHighest;
  }

  Color _surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }
}
