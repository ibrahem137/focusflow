import 'package:focus_flow/core/widgets/app_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/core/constants/theme/app_colors.dart';

import '../../logic/focus_cubit.dart';
import '../../logic/focus_state.dart';

class FocusScreen extends StatefulWidget {
  final bool isActive;

  const FocusScreen({super.key, this.isActive = false});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FocusCubit, FocusState>(
      builder: (context, state) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),

            child: Column(
              children: [
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.00,
                  end: 0.28,
                  offsetY: 18,
                  child: _buildHeader(context),
                ),
                const SizedBox(height: 42),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.10,
                  end: 0.48,
                  offsetY: 26,
                  beginScale: 0.88,
                  child: _buildTimer(context, state),
                ),
                const SizedBox(height: 36),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.28,
                  end: 0.58,
                  child: _buildDurationSelector(context, state),
                ),
                const SizedBox(height: 28),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.40,
                  end: 0.70,
                  child: _buildControls(context, state),
                ),
                const SizedBox(height: 28),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.54,
                  end: 0.84,
                  offsetY: 18,
                  child: _buildGardenMessage(context),
                ),
                const SizedBox(height: 22),
                AppEntrance(
                  controller: _entranceController,
                  begin: 0.68,
                  end: 1.00,
                  offsetY: 18,
                  child: _buildTodayStats(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant FocusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      duration: const Duration(milliseconds: 1250),
    );
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playEntranceAnimation();
      });
    }
  }

  Color _borderColor(BuildContext context) {
    final theme = Theme.of(context);

    return theme.colorScheme.outlineVariant;
  }

  // ===========================================================================

  // Controls

  // ===========================================================================

  Widget _buildControls(BuildContext context, FocusState state) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,

            child: FilledButton.icon(
              onPressed: () {
                context.read<FocusCubit>().toggle();
              },

              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),

              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),

                child: Icon(
                  state.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,

                  key: ValueKey(state.isRunning),
                ),
              ),

              label: Text(
                state.isRunning
                    ? 'Pause'
                    : state.status == FocusStatus.paused
                    ? 'Resume'
                    : 'Start Focus',

                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        SizedBox(
          width: 56,

          height: 56,

          child: IconButton(
            onPressed: () {
              context.read<FocusCubit>().reset();
            },

            style: IconButton.styleFrom(
              backgroundColor: _surface(context),

              foregroundColor: _primaryText(context),

              side: BorderSide(color: _borderColor(context)),
            ),

            tooltip: 'Reset session',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
    );
  }

  // ===========================================================================

  // Duration Selector

  // ===========================================================================

  Widget _buildDurationSelector(BuildContext context, FocusState state) {
    return Container(
      padding: const EdgeInsets.all(5),

      decoration: BoxDecoration(
        color: _surface(context),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: _borderColor(context)),
      ),

      child: Row(
        children: [
          _durationButton(context, state, 15),
          _durationButton(context, state, 25),

          _durationButton(context, state, 45),

          _durationButton(context, state, 60),
        ],
      ),
    );
  }

  // ===========================================================================

  // Garden Message

  // ===========================================================================

  Widget _buildGardenMessage(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.07 : 0.06,
        ),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: AppColors.secondary.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.18
                : 0.22,
          ),
        ),
      ),

      child: Row(
        children: [
          const Icon(Icons.eco_rounded, size: 28, color: AppColors.secondary),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              'Complete this session to grow your focus garden.',

              style: TextStyle(
                color: _secondaryText(context),

                height: 1.4,

                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================

  // Header

  // ===========================================================================

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Text(
          'FOCUS',

          style: TextStyle(
            color: AppColors.primary,

            fontSize: 12,

            fontWeight: FontWeight.w800,

            letterSpacing: 2.5,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Deep Work Session',

          style: Theme.of(context).textTheme.headlineMedium,
        ),

        const SizedBox(height: 7),

        Text(
          'Stay focused. You\'ve got this.',

          style: TextStyle(color: _secondaryText(context), fontSize: 13),
        ),
      ],
    );
  }

  // ===========================================================================

  // Timer

  // ===========================================================================

  Widget _buildTimer(BuildContext context, FocusState state) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: state.progress),

      duration: const Duration(milliseconds: 400),

      builder: (context, value, child) {
        return SizedBox(
          width: 250,

          height: 250,

          child: Stack(
            alignment: Alignment.center,

            children: [
              // Outer subtle glow

              AnimatedContainer(
                duration: const Duration(milliseconds: 350),

                width: 244,

                height: 244,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: state.isRunning
                            ? theme.brightness == Brightness.dark
                                  ? 0.18
                                  : 0.12
                            : theme.brightness == Brightness.dark
                            ? 0.06
                            : 0.05,
                      ),

                      blurRadius: state.isRunning ? 40 : 25,

                      spreadRadius: state.isRunning ? 4 : 1,
                    ),
                  ],
                ),
              ),

              // Progress ring
              SizedBox(
                width: 250,

                height: 250,

                child: CircularProgressIndicator(
                  value: value,

                  strokeWidth: 10,

                  strokeCap: StrokeCap.round,

                  backgroundColor: _softSurface(context),

                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),

              // Inner timer
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),

                width: 205,

                height: 205,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  color: _surface(context),

                  border: Border.all(color: _borderColor(context)),

                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: state.isRunning
                            ? theme.brightness == Brightness.dark
                                  ? 0.16
                                  : 0.08
                            : 0.03,
                      ),

                      blurRadius: 35,

                      spreadRadius: 2,
                    ),
                  ],
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        state.formattedTime,

                        style: TextStyle(
                          color: _primaryText(context),

                          fontSize: 48,

                          fontWeight: FontWeight.w700,

                          letterSpacing: -1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),

                      child: Text(
                        _statusText(state.status),

                        key: ValueKey(state.status),

                        style: TextStyle(
                          color: state.isRunning
                              ? AppColors.secondary
                              : state.status == FocusStatus.paused
                              ? AppColors.primary
                              : _secondaryText(context),

                          fontSize: 11,

                          fontWeight: FontWeight.w800,

                          letterSpacing: 2,
                        ),
                      ),
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

  // Today Stats

  // ===========================================================================

  Widget _buildTodayStats(BuildContext context, FocusState state) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: _surface(context),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: _borderColor(context)),
      ),

      child: Row(
        children: [
          Expanded(
            child: _FocusStat(
              value: _formatFocusTime(state.totalFocusMinutes),

              label: 'Focus time',
            ),
          ),

          SizedBox(
            height: 35,

            child: VerticalDivider(color: _borderColor(context)),
          ),

          Expanded(
            child: _FocusStat(
              value: '${state.completedSessions}',

              label: 'Sessions',
            ),
          ),
        ],
      ),
    );
  }

  Widget _durationButton(BuildContext context, FocusState state, int minutes) {
    final selected = state.selectedMinutes == minutes;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<FocusCubit>().selectDuration(minutes);
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),

          curve: Curves.easeOut,

          padding: const EdgeInsets.symmetric(vertical: 12),

          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,

            borderRadius: BorderRadius.circular(13),

            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.20),

                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),

          child: Text(
            '$minutes min',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: selected ? Colors.white : _secondaryText(context),

              fontWeight: FontWeight.w700,

              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================

  // Helpers

  // ===========================================================================

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

  void _playEntranceAnimation() {
    if (!mounted) return;
    _entranceController
      ..stop()
      ..reset()
      ..forward();
  }

  Color _primaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _secondaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  // ===========================================================================

  // Complete Dialog

  // ===========================================================================

  Color _softSurface(BuildContext context) {
    final theme = Theme.of(context);

    return theme.colorScheme.surfaceContainerHighest;
  }

  String _statusText(FocusStatus status) {
    switch (status) {
      case FocusStatus.ready:
        return 'READY';

      case FocusStatus.running:
        return 'FOCUSING';

      case FocusStatus.paused:
        return 'PAUSED';

      case FocusStatus.completed:
        return 'COMPLETED';
    }
  }

  // ===========================================================================

  // Theme Helpers

  // ===========================================================================

  Color _surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }
}

// =============================================================================

// Focus Stat

// =============================================================================

class _FocusStat extends StatelessWidget {
  final String value;

  final String label;

  const _FocusStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,

          style: TextStyle(
            color: colors.onSurface,

            fontSize: 18,

            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,

          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }
}
