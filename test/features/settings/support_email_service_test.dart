import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/constants/support_config.dart';
import 'package:focus_flow/core/services/support_email_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SupportEmailService service({Future<bool> Function(Uri)? launch}) =>
      SupportEmailService(
        address: 'developer@example.com',
        launch: launch,
        technicalInfo: () async => const SupportTechnicalInfo(
          version: '1.2.3',
          buildNumber: '7',
          platform: 'android',
        ),
      );
  test(
    'feedback preserves Arabic, punctuation and newlines in mailto encoding',
    () async {
      const text = 'اقتراح + تحسين & تجربة؟\nline two #100%';
      final draft = await service().prepare(
        SupportRequest.feedback,
        '  $text  ',
      );
      expect(draft.subject, 'FocusFlow - Feedback');
      expect(draft.body, text);
      expect(draft.uri.scheme, 'mailto');
      expect(draft.uri.path, 'developer@example.com');
      expect(draft.uri.queryParameters, {
        'subject': draft.subject,
        'body': text,
      });
      expect(draft.uri.query, isNot(contains('+')));
    },
  );
  test(
    'problem report appends exactly the permitted technical information',
    () async {
      final draft = await service().prepare(
        SupportRequest.problem,
        'Screen issue',
      );
      expect(draft.subject, 'FocusFlow - Problem Report');
      expect(
        draft.body,
        'Screen issue\n\n--- Technical information (automatically included) ---\nApp: FocusFlow\nVersion: 1.2.3\nBuild: 7\nPlatform: android',
      );
    },
  );
  test('platform package information exposes only version and build', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Private label',
      packageName: 'private.package',
      version: '2.0',
      buildNumber: '9',
      buildSignature: 'private-signature',
      installerStore: 'private-installer',
    );
    final draft = await SupportEmailService().prepare(
      SupportRequest.problem,
      'Issue',
    );
    expect(
      draft.body,
      endsWith(
        'App: FocusFlow\nVersion: 2.0\nBuild: 9\nPlatform: ${defaultTargetPlatform.name}',
      ),
    );
    expect(draft.body, isNot(contains('private')));
  });
  test(
    'contact uses an empty body without reading technical information',
    () async {
      final s = SupportEmailService(
        technicalInfo: () => throw StateError('Not allowed'),
      );
      final draft = await s.prepare(SupportRequest.contact, 'ignored');
      expect(draft.subject, 'FocusFlow - Contact');
      expect(draft.body, isEmpty);
    },
  );
  test('feedback does not collect technical information', () async {
    final s = SupportEmailService(
      technicalInfo: () => throw StateError('Not allowed'),
    );
    expect((await s.prepare(SupportRequest.feedback, 'Idea')).body, 'Idea');
  });
  test('metadata failure keeps the user report usable', () async {
    final s = SupportEmailService(
      technicalInfo: () => throw StateError('Unavailable'),
    );
    final draft = await s.prepare(SupportRequest.problem, 'Keep this report');
    expect(draft.body, startsWith('Keep this report\n\n'));
    expect(draft.body, contains('Technical information unavailable.'));
  });
  test('empty and oversized messages are rejected', () async {
    for (final text in [' \n ', 'a' * (SupportConfig.maxMessageLength + 1)]) {
      await expectLater(
        service().prepare(SupportRequest.feedback, text),
        throwsArgumentError,
      );
    }
  });
  test('configured service hands off the expected URI', () async {
    Uri? opened;
    final s = service(
      launch: (uri) async {
        opened = uri;
        return true;
      },
    );
    final draft = await s.prepare(SupportRequest.feedback, 'Idea');
    expect(await s.open(draft), true);
    expect(opened, draft.uri);
  });
  test('unconfigured support never launches its placeholder', () async {
    var calls = 0;

    final s = SupportEmailService(
      address: 'YOUR_SUPPORT_EMAIL_HERE',
      launch: (_) async {
        calls++;
        return true;
      },
    );

    expect(s.configured, false);
    expect(await s.open(await s.prepare(SupportRequest.contact, '')), false);
    expect(calls, 0);
  });
  test('false and thrown launch results become recoverable failures', () async {
    for (final launch in <Future<bool> Function(Uri)>[
      (_) async => false,
      (_) async => throw StateError('No app'),
    ]) {
      final s = service(launch: launch);
      expect(
        await s.open(await s.prepare(SupportRequest.feedback, 'Keep me')),
        false,
      );
    }
  });
}
