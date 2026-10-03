import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/rewards.dart';
import '../services/app_repository.dart';
import '../../features/focus/logic/focus_cubit.dart';
import '../../features/focus/logic/focus_state.dart';
import '../../features/progress/logic/progress_cubit.dart';
import '../../features/progress/logic/progress_state.dart';
import '../../features/settings/logic/settings_cubit.dart';
import '../../features/achievements/logic/achievement.dart';
import '../../features/achievements/logic/achievements_cubit.dart';

class AppFeedback extends StatefulWidget {
  final Widget child;
  const AppFeedback({super.key, required this.child});
  @override
  State<AppFeedback> createState() => _AppFeedbackState();
}

class _AppFeedbackState extends State<AppFeedback> with WidgetsBindingObserver {
  Timer? _dayRefresh;
  late final AppRepository _repository;
  void _onStorageError() {
    final error = _repository.error.value;
    if (mounted && error != null) _message(error);
  }

  @override
  void initState() {
    super.initState();
    _repository = context.read<AppRepository>();
    _repository.error.addListener(_onStorageError);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<FocusCubit>().loadFocusData();
    });
    // Refresh derived day/week/streak values across midnight without persisting ticks.
    _dayRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        context.read<FocusCubit>().refreshCalendar();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<FocusCubit>().reconcile();
      context.read<FocusCubit>().refreshCalendar();
      context.read<SettingsCubit>().syncReminders();
    }
  }

  @override
  void dispose() {
    _repository.error.removeListener(_onStorageError);
    _dayRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<FocusCubit, FocusState>(
        listenWhen: (a, b) =>
            a.status != b.status && b.status == FocusStatus.completed,
        listener: (context, state) async {
          final settings = context.read<SettingsCubit>();
          unawaited(settings.syncReminders());
          try {
            await settings.reminders.complete(
              sound: settings.state['sound'] == true,
              haptics: settings.state['haptics'] == true,
            );
          } catch (_) {
            /* Device feedback is optional. */
          }
          if (!context.mounted) return;
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (c) => AlertDialog(
              scrollable: true,
              title: const Text('Session completed! 🌱'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: MediaQuery.disableAnimationsOf(c)
                        ? Duration.zero
                        : const Duration(milliseconds: 550),
                    curve: Curves.easeOutBack,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 72,
                      color: Theme.of(c).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${state.selectedMinutes} focused minutes · +${Rewards.focusXp(state.selectedMinutes)} XP',
                  ),
                  const SizedBox(height: 12),
                  const Text('Great work! Your focus garden just grew.'),
                  const SizedBox(height: 8),
                  Text(
                    '${state.currentStreak} day streak · Best ${state.bestStreak}',
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(c);
                    context.read<FocusCubit>().prepareNextSession();
                  },
                  child: const Text('Next Session'),
                ),
              ],
            ),
          );
        },
      ),
      BlocListener<ProgressCubit, ProgressState>(
        listenWhen: (a, b) => b.level > a.level,
        listener: (_, s) =>
            _message('Level ${s.level}! Your focus is paying off.'),
      ),
      BlocListener<AchievementsCubit, Map<String, DateTime>>(
        listenWhen: (a, b) => b.length > a.length,
        listener: (_, s) {
          final recent = s.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final badge = Achievement.all.firstWhere(
            (b) => b.id == recent.first.key,
          );
          _message('Achievement unlocked: ${badge.title}');
        },
      ),
    ],
    child: ValueListenableBuilder<String?>(
      valueListenable: context.read<AppRepository>().error,
      builder: (context, error, _) => Column(
        children: [
          if (error != null)
            SafeArea(
              bottom: false,
              child: MaterialBanner(
                content: Text(error),
                actions: [
                  TextButton(
                    onPressed: () =>
                        context.read<AppRepository>().error.value = null,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    ),
  );
}
