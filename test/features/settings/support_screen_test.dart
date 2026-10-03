import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/constants/theme/app_theme.dart';
import 'package:focus_flow/core/constants/theme/logic/theme_cubit.dart';
import 'package:focus_flow/core/services/app_repository.dart';
import 'package:focus_flow/core/services/support_email_service.dart';
import 'package:focus_flow/features/focus/logic/focus_cubit.dart';
import 'package:focus_flow/features/settings/logic/settings_cubit.dart';
import 'package:focus_flow/features/settings/ui/settings_screen.dart';
import 'package:focus_flow/features/settings/ui/support_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    const path = String.fromEnvironment('REVIEW_FONT');
    if (path.isNotEmpty) {
      final fonts = FontLoader('Roboto')
        ..addFont(File(path).readAsBytes().then(ByteData.sublistView));
      await fonts.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File('${File(path).parent.path}/MaterialIcons-Regular.otf')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      await icons.load();
    }
  });
  final launched = <Uri>[];
  late SupportEmailService service;
  setUp(() {
    launched.clear();
    service = SupportEmailService(
      address: 'developer@example.com',
      launch: (uri) async {
        launched.add(uri);
        return false;
      },
      technicalInfo: () async => const SupportTechnicalInfo(
        version: '1.0.0',
        buildNumber: '1',
        platform: 'android',
      ),
    );
  });
  Widget host(
    SupportRequest request, {
    bool dark = false,
    double scale = 1,
    SupportEmailService? email,
  }) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: child!,
    ),
    home: RepaintBoundary(
      key: const ValueKey('support-capture'),
      child: SupportScreen(request: request, service: email ?? service),
    ),
  );
  final send = find.byKey(const ValueKey('support-send'));
  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
  }

  testWidgets('Settings opens feedback and retains existing haptic behavior', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final r = AppRepository();
    await tester.runAsync(r.load);
    final s = SettingsCubit(r);
    final t = ThemeCubit(repository: r);
    final f = FocusCubit(repository: r);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: s),
          BlocProvider.value(value: t),
          BlocProvider.value(value: f),
        ],
        child: MaterialApp(home: SettingsScreen(supportService: service)),
      ),
    );
    await tester.tap(find.widgetWithText(SwitchListTile, 'Haptic feedback'));
    await tester.pumpAndSettle();
    expect(r.settings['haptics'], false);
    await tester.scrollUntilVisible(find.text('Send Feedback'), 250);
    expect(find.text('Support & Feedback'), findsOneWidget);
    expect(find.text('Report a Problem'), findsOneWidget);
    expect(find.text('Contact Us'), findsOneWidget);
    await tester.ensureVisible(find.text('Send Feedback'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Feedback'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(
      find.text(
        "We'd love to hear from you. Share an idea or tell us how we can make FocusFlow better.",
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await s.close();
      await t.close();
      await f.close();
      await r.dispose();
    });
  });
  testWidgets('whitespace cannot be submitted', (tester) async {
    await tester.pumpWidget(host(SupportRequest.feedback));
    await tester.enterText(find.byType(TextFormField), ' \n ');
    await submit(tester);
    expect(
      find.text('Please write a message before continuing.'),
      findsOneWidget,
    );
    expect(launched, isEmpty);
  });
  testWidgets('failed email handoff keeps text and copies the full draft', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(host(SupportRequest.feedback));
    await tester.enterText(find.byType(TextFormField), 'اقتراح & idea');
    await submit(tester);
    expect(launched.single.queryParameters['subject'], 'FocusFlow - Feedback');
    expect(find.textContaining("Couldn't open an email app."), findsOneWidget);
    expect(find.text('اقتراح & idea'), findsOneWidget);
    await tester.ensureVisible(find.text('Copy message'));
    await tester.tap(find.text('Copy message'));
    await tester.pumpAndSettle();
    expect(copied, 'FocusFlow - Feedback\n\nاقتراح & idea');
  });
  testWidgets(
    'problem report includes the entered message and allowed metadata',
    (tester) async {
      await tester.pumpWidget(host(SupportRequest.problem));
      await tester.enterText(find.byType(TextFormField), 'Screen issue');
      await submit(tester);
      expect(
        launched.single.queryParameters['subject'],
        'FocusFlow - Problem Report',
      );
      expect(
        launched.single.queryParameters['body'],
        startsWith('Screen issue\n\n--- Technical information'),
      );
      expect(
        launched.single.queryParameters['body'],
        endsWith('Platform: android'),
      );
    },
  );
  testWidgets('Contact Us opens a contact draft and offers address copying', (
    tester,
  ) async {
    await tester.pumpWidget(host(SupportRequest.contact));
    await tester.pumpAndSettle();
    expect(launched.single.queryParameters, {
      'subject': 'FocusFlow - Contact',
      'body': '',
    });
    expect(find.text('Copy email address'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
  testWidgets(
    'repeated taps launch once and successful handoff retains the draft',
    (tester) async {
      final gate = Completer<bool>();
      var calls = 0;
      final s = SupportEmailService(
        address: 'developer@example.com',
        launch: (_) {
          calls++;
          return gate.future;
        },
      );
      await tester.pumpWidget(host(SupportRequest.feedback, email: s));
      await tester.enterText(find.byType(TextFormField), 'Keep this');
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pump();
      await tester.tap(send);
      await tester.pump();
      expect(calls, 1);
      gate.complete(true);
      await tester.pumpAndSettle();
      expect(find.textContaining('Email app opened.'), findsOneWidget);
      expect(find.text('Keep this'), findsOneWidget);
    },
  );
  testWidgets(
    'an unresponsive launcher releases the controls and retains the draft',
    (tester) async {
      final gate = Completer<bool>();
      final slow = SupportEmailService(
        address: 'developer@example.com',
        launch: (_) => gate.future,
      );
      await tester.pumpWidget(host(SupportRequest.feedback, email: slow));
      await tester.enterText(find.byType(TextFormField), 'Keep my draft');
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pump();
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(
        find.textContaining("Couldn't open an email app."),
        findsOneWidget,
      );
      expect(find.text('Keep my draft'), findsOneWidget);
      expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
      gate.complete(false);
    },
  );
  testWidgets('missing address offers copying without losing feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SupportRequest.feedback,
        email: SupportEmailService(address: 'YOUR_SUPPORT_EMAIL_HERE'),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'Keep the idea');
    await submit(tester);
    expect(find.textContaining('not been configured'), findsOneWidget);
    expect(find.text('Copy message'), findsOneWidget);
    expect(find.text('Keep the idea'), findsOneWidget);
  });
  testWidgets('back requires confirmation before discarding a draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SupportScreen(
                  request: SupportRequest.feedback,
                  service: service,
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'My draft');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard this draft?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('My draft'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });
  for (final dark in [false, true]) {
    for (final request in SupportRequest.values) {
      testWidgets(
        '${request.name} small keyboard large text ${dark ? 'dark' : 'light'}',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpWidget(host(request, dark: dark, scale: 1.5));
          await tester.pumpAndSettle();
          if (request != SupportRequest.contact) {
            await tester.enterText(
              find.byType(TextFormField),
              'Long feedback. ' * 100,
            );
          }
          await submit(tester);
          expect(tester.takeException(), isNull);
          expect(
            find.textContaining("Couldn't open an email app."),
            findsOneWidget,
          );
        },
      );
      testWidgets('${request.name} phone layout ${dark ? 'dark' : 'light'}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(host(request, dark: dark));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_SUPPORT')) {
          await expectLater(
            find.byKey(const ValueKey('support-capture')),
            matchesGoldenFile(
              'goldens/${request.name}_${dark ? 'dark' : 'light'}.png',
            ),
          );
        }
      });
    }
  }
}
