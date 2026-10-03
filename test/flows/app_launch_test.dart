import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_flow/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  for (final size in [const Size(800, 600), const Size(320, 640)]) {
    testWidgets(
      'first launch then skip opens the five-tab application at $size',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = size.width == 320
            ? 1.5
            : 1;
        try {
          await tester.pumpWidget(const FocusFlowApp());
          await tester.pump(const Duration(seconds: 1));
          for (var frame = 0; frame < 8; frame++) {
            await tester.pump(const Duration(milliseconds: 500));
          }
          expect(find.text('Plan Meaningful Tasks'), findsOneWidget);
          await tester.tap(find.text('Skip'));
          // Main navigation contains intentional living animations, so use bounded pumps.
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 2));
          expect(find.byTooltip('Settings'), findsOneWidget);
          expect(find.text('Home'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Settings'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.text('Appearance'), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        } finally {
          debugDefaultTargetPlatformOverride = null;
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        }
      },
    );
  }
}
