import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_flow/features/splash/ui/splash_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_flow/core/constants/theme/app_theme.dart';
import 'package:focus_flow/core/constants/theme/logic/theme_cubit.dart';
import 'package:focus_flow/core/services/app_repository.dart';
import 'package:focus_flow/features/settings/logic/settings_cubit.dart';
import 'package:focus_flow/features/achievements/logic/achievements_cubit.dart';
import 'package:focus_flow/features/progress/logic/progress_cubit.dart';
import 'package:focus_flow/features/focus/logic/focus_cubit.dart';
import 'package:focus_flow/features/tasks/logic/tasks_cubit.dart';
import 'package:focus_flow/features/home/ui/screens/home_screen.dart';
import 'package:focus_flow/features/focus/ui/screens/focus_screen.dart';
import 'package:focus_flow/features/tasks/ui/screens/tasks_screen.dart';
import 'package:focus_flow/features/garden/ui/screens/garden_screen.dart';
import 'package:focus_flow/features/stats/ui/screens/stats_screen.dart';
import 'package:focus_flow/features/settings/ui/settings_screen.dart';
import 'package:focus_flow/features/achievements/ui/achievements_screen.dart';
import 'package:focus_flow/features/onboarding/ui/onboarding_screen.dart';

void main() {
  setUpAll(() async {
    // Optional SDK font for human-readable review captures; normal layout tests
    // retain Flutter's deliberately wide test font to expose tight constraints.
    const fontPath = String.fromEnvironment('REVIEW_FONT');
    if (fontPath.isNotEmpty) {
      final loader = FontLoader('Roboto');
      loader.addFont(File(fontPath).readAsBytes().then(ByteData.sublistView));
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File('${File(fontPath).parent.path}/MaterialIcons-Regular.otf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
      await icons.load();
    }
  });
  late AppRepository repository;
  late ThemeCubit theme;
  late TasksCubit tasks;
  late FocusCubit focus;
  late ProgressCubit progress;
  late SettingsCubit settings;
  late AchievementsCubit achievements;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = AppRepository();
    await repository.load();
    theme = ThemeCubit(repository: repository);
    tasks = TasksCubit(repository: repository);
    focus = FocusCubit(repository: repository);
    progress = ProgressCubit(repository: repository);
    settings = SettingsCubit(repository);
    achievements = AchievementsCubit(repository);
  });
  tearDown(() async {
    await theme.close();
    await tasks.close();
    await focus.close();
    await progress.close();
    await settings.close();
    await achievements.close();
    await repository.dispose();
  });
  final screens = <String, Widget Function()>{
    'splash': () => SplashScreen(onFinished: () {}),
    'home': () =>
        HomeScreen(isActive: true, onStartFocus: () {}, onSeeAllTasks: () {}),
    'tasks': () => const TasksScreen(isActive: true),
    'focus': () => const FocusScreen(isActive: true),
    'garden': () => const GardenScreen(isActive: true),
    'stats': () => const StatsScreen(isActive: true),
    'settings': () => const SettingsScreen(),
    'achievements': () => const AchievementsScreen(),
    'onboarding': () => const OnboardingScreen(),
  };
  for (final populated in [false, true]) {
    for (final dark in [false, true]) {
      for (final size in [
        const Size(390, 844),
        const Size(320, 640),
        const Size(640, 360),
      ]) {
        for (final screen in screens.entries) {
          testWidgets(
            '${screen.key} ${dark ? 'dark' : 'light'} ${size.width} ${populated ? 'populated' : 'empty'}',
            (tester) async {
              if (populated) {
                await tester.runAsync(
                  () => repository.update((d) {
                    d['tasks'] = List.generate(
                      4,
                      (i) => {
                        'id': 'task-$i',
                        'title':
                            'A meaningful task with a long title to verify readable content and reliable editing $i',
                        'category': 'Personal development',
                        'xp': 50,
                        'isCompleted': i < 2,
                        'rewardClaimed': i == 0,
                      },
                    );
                    d['completedTaskIds'] = ['task-0', 'task-1'];
                    d['rewardIds'] = ['task:task-0'];
                    d['xp'] = 12345;
                    d['sessions'] = List.generate(
                      50,
                      (i) => {
                        'id': 'focus-$i',
                        'minutes': 25 + i,
                        'completedAt': DateTime.now()
                            .subtract(Duration(hours: i * 8))
                            .toIso8601String(),
                      },
                    );
                  }),
                );
              }
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              await tester.pumpWidget(
                RepositoryProvider.value(
                  value: repository,
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: theme),
                      BlocProvider.value(value: tasks),
                      BlocProvider.value(value: focus),
                      BlocProvider.value(value: progress),
                      BlocProvider.value(value: settings),
                      BlocProvider.value(value: achievements),
                    ],
                    child: MaterialApp(
                      theme: dark ? AppTheme.dark : AppTheme.light,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          disableAnimations: true,
                          textScaler: TextScaler.linear(
                            size.width == 320 ? 1.5 : 1,
                          ),
                        ),
                        child: child!,
                      ),
                      home: Scaffold(
                        body: RepaintBoundary(
                          key: const ValueKey('screen'),
                          child: SizedBox.expand(
                            child: ColoredBox(
                              color: (dark ? AppTheme.dark : AppTheme.light)
                                  .scaffoldBackgroundColor,
                              child: screen.value(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              // Startup waits for an end-of-frame callback before revealing art.
              await tester.pump();
              await tester.pump(const Duration(seconds: 2));
              expect(tester.takeException(), isNull);
              // Stable, reduced-motion visual baselines at a representative phone size.
              if (size.width == 390 &&
                  const bool.fromEnvironment('CAPTURE_GOLDENS')) {
                await expectLater(
                  find.byKey(const ValueKey('screen')),
                  matchesGoldenFile(
                    'goldens/${screen.key}_${dark ? 'dark' : 'light'}${populated ? '_populated' : ''}.png',
                  ),
                );
              }
              await tester.pumpWidget(const SizedBox());
            },
          );
        }
      }
    }
  }
}
