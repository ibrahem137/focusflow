import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/theme/app_theme.dart';
import 'core/constants/theme/logic/theme_cubit.dart';
import 'core/constants/theme/logic/theme_state.dart';
import 'core/services/app_repository.dart';
import 'core/widgets/app_feedback.dart';
import 'core/widgets/main_navigation.dart';
import 'features/achievements/logic/achievements_cubit.dart';
import 'features/focus/logic/focus_cubit.dart';
import 'features/onboarding/ui/onboarding_screen.dart';
import 'features/progress/logic/progress_cubit.dart';
import 'features/settings/logic/settings_cubit.dart';
import 'features/splash/ui/splash_screen.dart';
import 'features/tasks/logic/tasks_cubit.dart';

class FocusFlowApp extends StatefulWidget {
  final AppRepository? repository;
  const FocusFlowApp({super.key, this.repository});

  @override
  State<FocusFlowApp> createState() => _FocusFlowAppState();
}

class _FocusFlowAppState extends State<FocusFlowApp> {
  late final AppRepository _repository = widget.repository ?? AppRepository();
  bool _splashFinished = false;
  bool _ready = false;
  bool _loadFailed = false;

  Future<void> _initialize() async {
    setState(() => _loadFailed = false);
    try {
      await _repository.load();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready && _splashFinished) {
      return _LoadedApp(repository: _repository);
    }
    // Exactly one MaterialApp/Navigator is mounted, including during retries.
    return MaterialApp(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: !_splashFinished
          ? SplashScreen(
              onFinished: () {
                if (mounted) setState(() => _splashFinished = true);
              },
            )
          : _loadFailed
          ? _LoadErrorScreen(onRetry: _initialize)
          : const Scaffold(
              backgroundColor: Color(0xFF090711),
              body: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Opening your saved data',
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    if (widget.repository == null) unawaited(_repository.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }
}

class _LaunchGate extends StatelessWidget {
  const _LaunchGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, Map<String, dynamic>>(
      buildWhen: (previous, current) {
        return previous['onboarded'] != current['onboarded'];
      },
      builder: (context, settings) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: settings['onboarded'] == true
              ? const MainNavigation(key: ValueKey('main-navigation'))
              : const OnboardingScreen(key: ValueKey('onboarding')),
        );
      },
    );
  }
}

class _LoadedApp extends StatelessWidget {
  final AppRepository repository;

  const _LoadedApp({required this.repository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(repository: repository)),
          BlocProvider(create: (_) => ProgressCubit(repository: repository)),
          BlocProvider(create: (_) => TasksCubit(repository: repository)),
          BlocProvider(
            create: (_) => SettingsCubit(repository)..syncReminders(),
          ),
          BlocProvider(create: (_) => AchievementsCubit(repository)),
          BlocProvider(create: (_) => FocusCubit(repository: repository)),
        ],
        child: const _ThemedApp(),
      ),
    );
  }
}

class _LoadErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090711),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 42,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your saved data could not be opened.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your existing data has not been overwritten.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, theme) {
        return MaterialApp(
          title: 'FocusFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          home: const AppFeedback(child: _LaunchGate()),
        );
      },
    );
  }
}
