import '../../helpers/fixtures.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/progress/logic/progress_cubit.dart';
import 'package:focus_flow/features/tasks/logic/tasks_cubit.dart';
import 'package:focus_flow/features/tasks/ui/screens/tasks_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late TasksCubit tasksCubit;
  late ProgressCubit progressCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues(legacyTaskFixture());

    tasksCubit = TasksCubit();
    await tasksCubit.loadTasks();
    progressCubit = ProgressCubit(repository: tasksCubit.repository);
  });

  tearDown(() async {
    await tasksCubit.close();
    await progressCubit.close();
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TasksCubit>.value(value: tasksCubit),
        BlocProvider<ProgressCubit>.value(value: progressCubit),
      ],
      child: const MaterialApp(home: Scaffold(body: TasksScreen())),
    );
  }

  testWidgets('edit dialog stays usable with keyboard on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final original = tasksCubit.state.tasks.first;
    await tester.pumpWidget(buildTestWidget());
    await tester.tap(find.byTooltip('Edit task').first);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Updated task title');
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.runAsync(() => tasksCubit.repository.flush());
    await tester.pumpAndSettle();
    final edited = tasksCubit.state.tasks.first;
    expect(edited.id, original.id);
    expect(edited.xp, original.xp);
    expect(edited.title, 'Updated task title');
    expect(find.text('Edit Task'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('TasksScreen displays initial tasks', (
    WidgetTester tester,
  ) async {
    // Arrange + Act
    await tester.pumpWidget(buildTestWidget());

    // Assert
    expect(find.text('My Tasks'), findsOneWidget);

    expect(find.text('Study Laravel'), findsOneWidget);

    expect(find.text('Work on FocusFlow'), findsOneWidget);

    expect(find.text('Read 20 minutes'), findsOneWidget);

    expect(find.text('0 of 3 tasks completed'), findsOneWidget);

    expect(find.text('3 remaining'), findsOneWidget);
  });
  testWidgets('tapping add button opens Add New Task dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    // Act
    await tester.tap(find.byIcon(Icons.add_rounded));

    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Add New Task'), findsOneWidget);

    expect(find.text('What do you want to do?'), findsOneWidget);

    expect(find.text('Learning'), findsWidgets);

    expect(find.text('Work'), findsWidgets);

    expect(find.text('Personal'), findsWidgets);

    expect(find.text('+20 XP'), findsWidgets);

    expect(find.text('+40 XP'), findsWidgets);

    expect(find.text('+50 XP'), findsWidgets);

    expect(find.text('Cancel'), findsOneWidget);

    expect(find.text('Add Task'), findsOneWidget);
  });
  testWidgets('user can add a new task from the dialog', (
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(buildTestWidget());

    // Open dialog
    await tester.tap(find.byIcon(Icons.add_rounded));

    await tester.pumpAndSettle();

    expect(find.text('Add New Task'), findsOneWidget);

    // Enter task title
    await tester.enterText(find.byType(TextField), 'Learn Widget Testing');

    // Select Work category
    await tester.tap(find.text('Work').last);

    await tester.pump();

    // Select 50 XP
    await tester.tap(find.text('+50 XP').last);

    await tester.pump();

    // Submit
    await tester.tap(find.text('Add Task'));
    await tester.runAsync(() => tasksCubit.repository.flush());
    await tester.pumpAndSettle();

    // Assert UI
    expect(find.text('Add New Task'), findsNothing);

    expect(find.text('Learn Widget Testing'), findsOneWidget);

    expect(find.text('4 remaining'), findsOneWidget);

    expect(find.text('0 of 4 tasks completed'), findsOneWidget);

    // Assert Logic
    expect(tasksCubit.state.tasks.length, 4);

    final newTask = tasksCubit.state.tasks.last;

    expect(newTask.title, 'Learn Widget Testing');

    expect(newTask.category, 'Work');

    expect(newTask.xp, 50);
  });
  testWidgets('Cancel closes dialog without adding task', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    expect(tasksCubit.state.tasks.length, 3);

    await tester.tap(find.byIcon(Icons.add_rounded));

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'This should not be added');

    await tester.tap(find.text('Cancel'));

    await tester.pumpAndSettle();

    expect(find.text('Add New Task'), findsNothing);

    expect(find.text('This should not be added'), findsNothing);

    expect(tasksCubit.state.tasks.length, 3);
  });
  testWidgets('user can add a task with Arabic title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byIcon(Icons.add_rounded));

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'دراسة لارافيل');

    expect(find.text('دراسة لارافيل'), findsOneWidget);

    await tester.tap(find.text('Add Task'));
    await tester.runAsync(() => tasksCubit.repository.flush());
    await tester.pumpAndSettle();

    expect(find.text('دراسة لارافيل'), findsOneWidget);

    expect(tasksCubit.state.tasks.last.title, 'دراسة لارافيل');
  });
}
