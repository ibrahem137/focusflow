import '../widgets/garden_painters.dart';

import 'package:focus_flow/core/widgets/app_entrance.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/core/constants/theme/app_colors.dart';
import 'package:focus_flow/features/focus/logic/focus_cubit.dart';
import 'package:focus_flow/features/focus/logic/focus_state.dart';

class GardenScreen extends StatefulWidget {
  final bool isActive;

  const GardenScreen({super.key, required this.isActive});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

// =============================================================================
// Atmosphere: floating light / pollen
// =============================================================================

// =============================================================================
// Weekly Garden
// =============================================================================

class _GardenDay {
  final String day;
  final int sessions;
  final String time;
  final bool empty;

  const _GardenDay({
    required this.day,
    required this.sessions,
    required this.time,
    this.empty = false,
  });
}

class _GardenDayItem extends StatelessWidget {
  final _GardenDay data;
  final AnimationController lifeController;
  final double delay;

  const _GardenDayItem({
    required this.data,
    required this.lifeController,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final secondaryText = colors.onSurfaceVariant;
    final softSurface = theme.brightness == Brightness.dark
        ? colors.surfaceContainerHighest
        : const Color(0xFFF5F3FF);

    return AnimatedBuilder(
      animation: lifeController,
      builder: (context, child) {
        final phase = (lifeController.value + delay) % 1.0;
        final bob = data.empty ? 0.0 : math.sin(phase * math.pi * 2) * 1.6;

        return Column(
          children: [
            Text(
              data.day,
              style: TextStyle(color: secondaryText, fontSize: 10),
            ),
            const SizedBox(height: 13),
            Transform.translate(
              offset: Offset(0, bob),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.empty
                      ? softSurface
                      : AppColors.secondary.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.10
                              : 0.07,
                        ),
                ),
                child: Text(
                  data.empty ? '•' : _weeklyPlant(data.sessions),
                  style: TextStyle(
                    fontSize: data.empty ? 20 : 24,
                    color: data.empty ? secondaryText : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.time,
              style: TextStyle(
                color: data.empty ? secondaryText : colors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        );
      },
    );
  }

  String _weeklyPlant(int sessions) {
    if (sessions <= 0) return '•';
    if (sessions == 1) return '🌱';
    if (sessions == 2) return '🌿';
    if (sessions == 3) return '🌳';
    return '🌲';
  }
}

// =============================================================================
// Page entrance
// =============================================================================

class _GardenScreenState extends State<GardenScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _lifeController;
  late final AnimationController _growthController;

  int? _lastSessions;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FocusCubit, FocusState>(
      builder: (context, focusState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleSessionGrowth(focusState.todayCompletedSessions);
          }
        });

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.00,
                  end: 0.38,
                  child: _buildHeader(context),
                ),
                const SizedBox(height: 26),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.08,
                  end: 0.52,
                  beginScale: 0.94,
                  offsetY: 30,
                  child: _buildTodayTree(context, focusState),
                ),
                const SizedBox(height: 28),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.28,
                  end: 0.66,
                  child: _buildSectionTitle(
                    context,
                    title: 'This Week',
                    subtitle: 'Your focus journey',
                  ),
                ),
                const SizedBox(height: 16),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.36,
                  end: 0.78,
                  child: _buildWeeklyGarden(context, focusState),
                ),
                const SizedBox(height: 28),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.52,
                  end: 0.84,
                  child: _buildSectionTitle(
                    context,
                    title: 'Garden Stats',
                    subtitle: 'Every session makes it grow',
                  ),
                ),
                const SizedBox(height: 16),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.60,
                  end: 1.00,
                  child: _buildStats(context, focusState),
                ),
              ],
            ),
          ),
        );
      },
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
  void didUpdateWidget(covariant GardenScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _replayEntrance();
      _growthController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _lifeController.dispose();
    _growthController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );

    _lifeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _growthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    if (widget.isActive) {
      _entranceController.forward();
      _growthController.forward();
    }
  }

  Color _borderColor(BuildContext context) {
    final theme = Theme.of(context);

    return theme.colorScheme.outlineVariant;
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Focus Garden 🌱',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          context.watch<FocusCubit>().state.sessionHistory.isEmpty
              ? 'Your first focus session will plant the first seed.'
              : 'Your consistency is growing.',
          style: TextStyle(color: _secondaryText(context), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(color: _secondaryText(context), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context, FocusState state) {
    return Row(
      children: [
        Expanded(
          child: _GardenStatCard(
            icon: '🌳',
            value: '${state.completedSessions}',
            label: 'Sessions',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GardenStatCard(
            icon: '⏱️',
            value: _formatFocusTime(state.totalFocusMinutes),
            label: 'Focus time',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GardenStatCard(
            icon: '🔥',
            value: '${state.currentStreak}',
            label: 'Day streak',
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTree(BuildContext context, FocusState state) {
    final sessions = state.todayCompletedSessions;
    final focusMinutes = state.todayFocusMinutes;
    final levelName = _levelNameForSessions(sessions);
    final progress = _treeProgress(sessions);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_lifeController, _growthController]),
      builder: (context, _) {
        final life = MediaQuery.disableAnimationsOf(context)
            ? 0.5
            : _lifeController.value;
        final growth = MediaQuery.disableAnimationsOf(context)
            ? 1.0
            : Curves.easeOutBack.transform(
                _growthController.value.clamp(0.0, 1.0),
              );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withValues(alpha: isDark ? 0.16 : 0.09),
                AppColors.primary.withValues(alpha: isDark ? 0.11 : 0.06),
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.secondary.withValues(
                alpha: isDark ? 0.24 : 0.18,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(
                  alpha: isDark ? 0.08 : 0.05,
                ),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 245,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GardenAtmospherePainter(
                          progress: life,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Transform.scale(
                        scale: 0.88 + (growth * 0.12),
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: 230,
                          height: 220,
                          child: CustomPaint(
                            painter: LivingTreePainter(
                              sessions: sessions,
                              lifeProgress: life,
                              growthProgress: growth,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Today\'s Tree',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  '$sessions focus '
                  '${sessions == 1 ? 'session' : 'sessions'}'
                  ' • ${_formatFocusTime(focusMinutes)}',
                  key: ValueKey('$sessions-$focusMinutes'),
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor: _softSurface(context),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.secondary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 8,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      levelName,
                      key: ValueKey(levelName),
                      style: TextStyle(
                        color: _secondaryText(context),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    _nextLevelText(sessions),
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildWeeklyGarden(BuildContext context, FocusState state) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeklyMinutes = state.weeklyFocusMinutes;
    final weeklySessions = state.weeklySessionCounts;

    final days = List.generate(7, (index) {
      final minutes = weeklyMinutes[index];
      final sessions = weeklySessions[index];
      final isEmpty = sessions == 0;

      return _GardenDay(
        day: dayNames[index],
        sessions: sessions,
        time: isEmpty ? '--' : _formatFocusTime(minutes),
        empty: isEmpty,
      );
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor(context)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(days.length, (index) {
            return SizedBox(
              width: 48 * MediaQuery.textScalerOf(context).scale(1),
              child: _GardenDayItem(
                data: days[index],
                lifeController: _lifeController,
                delay: index * 0.08,
              ),
            );
          }),
        ),
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

  void _handleSessionGrowth(int sessions) {
    if (_lastSessions == null) {
      _lastSessions = sessions;
      return;
    }

    if (sessions > _lastSessions!) {
      _growthController
        ..reset()
        ..forward();
    }

    _lastSessions = sessions;
  }

  String _levelNameForSessions(int sessions) {
    if (sessions <= 0) return 'Resting soil';
    if (sessions == 1) return 'Fresh sprout';
    if (sessions == 2) return 'Young plant';
    if (sessions == 3) return 'Young tree';
    return 'Flourishing tree';
  }

  String _nextLevelText(int sessions) {
    if (sessions >= 4) {
      return 'Fully grown!';
    }

    final remainingSessions = 4 - sessions;

    if (remainingSessions == 1) {
      return '1 session to full growth';
    }

    return '$remainingSessions sessions to next level';
  }

  void _replayEntrance() {
    _entranceController
      ..stop()
      ..reset()
      ..forward();
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

  double _treeProgress(int sessions) {
    if (sessions <= 0) return 0;
    if (sessions >= 4) return 1;
    return sessions / 4;
  }
}

// =============================================================================
// Garden Stat Card
// =============================================================================

class _GardenStatCard extends StatefulWidget {
  final String icon;
  final String value;
  final String label;

  const _GardenStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  State<_GardenStatCard> createState() => _GardenStatCardState();
}

class _GardenStatCardState extends State<_GardenStatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final borderColor = theme.brightness == Brightness.dark
        ? colors.outlineVariant
        : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 7),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  widget.value,
                  key: ValueKey(widget.value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Living tree
// =============================================================================
