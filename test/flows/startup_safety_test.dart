import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_flow/app.dart';
import 'package:focus_flow/core/services/app_repository.dart';
import 'package:focus_flow/features/splash/ui/splash_screen.dart';

Future<void> finishIntro(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('slow storage retains a visible loading screen after the intro', (
    tester,
  ) async {
    final gate = Completer<SharedPreferences>();
    final repository = AppRepository(preferences: () => gate.future);
    await tester.pumpWidget(FocusFlowApp(repository: repository));
    await finishIntro(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    gate.complete(await SharedPreferences.getInstance());
    await tester.pump();
    await tester.pump();
    expect(find.text('Plan Meaningful Tasks'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await repository.dispose();
  });
  testWidgets('failed load retries in place without nesting applications', (
    tester,
  ) async {
    var fail = true;
    final repository = AppRepository(
      preferences: () {
        if (fail) throw StateError('Storage temporarily unavailable');
        return SharedPreferences.getInstance();
      },
    );
    await tester.pumpWidget(FocusFlowApp(repository: repository));
    await finishIntro(tester);
    expect(find.text('Your saved data could not be opened.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Plan Meaningful Tasks'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await repository.dispose();
  });
  testWidgets(
    'reduced-motion splash shows the finished artwork and finishes once',
    (tester) async {
      var finished = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: SplashScreen(onFinished: () => finished++),
        ),
      );
      await tester.pump();
      await tester.pump();
      final fades = tester.widgetList<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fades.every((fade) => fade.opacity.value == 1), true);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(finished, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
