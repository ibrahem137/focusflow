import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_flow/core/services/app_repository.dart';
import 'package:focus_flow/core/constants/theme/logic/theme_cubit.dart';
import 'package:focus_flow/features/settings/logic/settings_cubit.dart';
import 'package:focus_flow/features/settings/ui/settings_screen.dart';
import 'package:focus_flow/features/onboarding/ui/onboarding_screen.dart';
import 'package:focus_flow/features/focus/logic/focus_cubit.dart';
import 'package:focus_flow/features/focus/ui/screens/focus_screen.dart';
import 'package:focus_flow/features/tasks/logic/tasks_cubit.dart';
import 'package:focus_flow/features/tasks/ui/screens/tasks_screen.dart';

void main() {
  late AppRepository repository;
  late SettingsCubit settings;
  late FocusCubit focus;
  late ThemeCubit theme;
  late TasksCubit tasks;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = AppRepository();
    await repository.load();
    settings = SettingsCubit(repository);
    focus = FocusCubit(repository: repository);
    theme = ThemeCubit(repository: repository);
    tasks = TasksCubit(repository: repository);
  });
  tearDown(() async {
    await settings.close();
    await focus.close();
    await theme.close();
    await tasks.close();
    await repository.dispose();
  });
  Widget host(Widget child) => RepositoryProvider.value(
    value: repository,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settings),
        BlocProvider.value(value: focus),
        BlocProvider.value(value: theme),
        BlocProvider.value(value: tasks),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  testWidgets('onboarding next and get started persist completion', (
    tester,
  ) async {
    await tester.pumpWidget(host(const OnboardingScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Plan Meaningful Tasks'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(repository.settings['onboarded'], true);
  });
  testWidgets('skip persists completion', (tester) async {
    await tester.pumpWidget(host(const OnboardingScreen()));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(repository.settings['onboarded'], true);
  });
  testWidgets('settings exposes appearance focus and persisted haptics', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    final haptics = find.widgetWithText(SwitchListTile, 'Haptic feedback');
    await tester.ensureVisible(haptics);
    await tester.tap(haptics);
    await tester.pumpAndSettle();
    expect(repository.settings['haptics'], false);
  });
  testWidgets('focus starts pauses and resets from controls', (tester) async {
    await tester.pumpWidget(host(const FocusScreen(isActive: true)));
    await tester.pumpAndSettle();
    final start = find.text('Start Focus');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Resume'), findsOneWidget);
    await tester.tap(find.byTooltip('Reset session'));
    await tester.pumpAndSettle();
    expect(focus.state.remainingSeconds, 1500);
  });
  testWidgets('tasks has an honest empty state', (tester) async {
    await tester.pumpWidget(host(const TasksScreen(isActive: true)));
    await tester.pumpAndSettle();
    expect(tasks.state.tasks, isEmpty);
    expect(find.textContaining('No tasks'), findsWidgets);
  });
}
