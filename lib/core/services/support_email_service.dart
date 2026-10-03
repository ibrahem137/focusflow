import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/support_config.dart';

enum SupportRequest { feedback, problem, contact }

/// An explicit allow-list; this service never reads the app repository.
class SupportTechnicalInfo {
  final String version;
  final String buildNumber;
  final String platform;
  const SupportTechnicalInfo({
    required this.version,
    required this.buildNumber,
    required this.platform,
  });
  String get description =>
      'App: FocusFlow\nVersion: $version\nBuild: $buildNumber\nPlatform: $platform';
}

class SupportEmailDraft {
  final String address;
  final String subject;
  final String body;
  const SupportEmailDraft({
    required this.address,
    required this.subject,
    required this.body,
  });
  Uri get uri => Uri(
    scheme: 'mailto',
    path: address,
    // mailto requires %20 for spaces. queryParameters would encode them as +.
    query: {'subject': subject, 'body': body}.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&'),
  );
  String get copyText => '$subject\n\n$body';
}

class SupportEmailService {
  final String address;
  final Future<bool> Function(Uri) _launch;
  final Future<SupportTechnicalInfo> Function() _technicalInfo;
  SupportEmailService({
    this.address = SupportConfig.supportEmail,
    Future<bool> Function(Uri)? launch,
    Future<SupportTechnicalInfo> Function()? technicalInfo,
  }) : _launch = launch ?? _launchEmail,
       _technicalInfo = technicalInfo ?? _readTechnicalInfo;

  bool get configured =>
      RegExp(r'^[^@\s<>]+@[^@\s<>]+\.[^@\s<>]+$').hasMatch(address);
  static Future<bool> _launchEmail(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
  static Future<SupportTechnicalInfo> _readTechnicalInfo() async {
    final info = await PackageInfo.fromPlatform();
    return SupportTechnicalInfo(
      version: info.version,
      buildNumber: info.buildNumber,
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
    );
  }

  Future<SupportEmailDraft> prepare(SupportRequest request, String text) async {
    final message = text.trim();
    if (request != SupportRequest.contact &&
        (message.isEmpty ||
            text.characters.length > SupportConfig.maxMessageLength)) {
      throw ArgumentError(
        'Please enter 1–${SupportConfig.maxMessageLength} characters.',
      );
    }
    var body = request == SupportRequest.contact ? '' : message;
    if (request == SupportRequest.problem) {
      String details;
      try {
        details = (await _technicalInfo().timeout(const Duration(seconds: 5)))
            .description;
      } catch (_) {
        details = 'App: FocusFlow\nTechnical information unavailable.';
      }
      body =
          '$message\n\n--- Technical information (automatically included) ---\n$details';
    }
    return SupportEmailDraft(
      address: address,
      subject: switch (request) {
        SupportRequest.feedback => 'FocusFlow - Feedback',
        SupportRequest.problem => 'FocusFlow - Problem Report',
        SupportRequest.contact => 'FocusFlow - Contact',
      },
      body: body,
    );
  }

  Future<bool> open(SupportEmailDraft draft) async {
    if (!configured) return false;
    try {
      // Attempt directly; canLaunchUrl can return false without visibility queries.
      return await _launch(draft.uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      return false;
    }
  }
}
