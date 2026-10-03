# Support & Feedback — implementation report

September 28–29, 2026. Base: the reviewed FocusFlow source archive with 203 passing tests and a verified unsigned Android AAB. This change is limited to the new support feature.

## Added and UX

Settings now has a **Support & Feedback** card using its existing section helper, padding, typography and Material icons:

| Action | Behavior |
| --- | --- |
| Send Feedback | Opens a themed, scrollable form with a multiline field, friendly whitespace validation and a 2,000-character limit. It prepares `FocusFlow - Feedback`. |
| Report a Problem | Uses the same screen pattern; prepares `FocusFlow - Problem Report` and appends a clearly separated technical-information block. |
| Contact Us | Opens its support screen and immediately attempts an email draft with subject `FocusFlow - Contact` and an empty body. The screen remains available for retry/address copying. |

Routes match existing Settings/Achievements navigation. With reduced motion enabled, the new support route has zero-duration transitions and the pending indicator is static. The form uses the current ColorScheme and card/input theme, a 600-pixel content maximum width, keyboard-resizing Scaffold and scrolling. Light/dark render captures and small-screen/150%-text keyboard tests cover the new forms. System theme inherits the application's existing theme selection.

No email is sent by FocusFlow. A successful handoff means only that an external email client opened; the user reviews and sends there. The draft remains on screen even after success. Repeated submission taps are disabled during preparation/launch; repeated route taps are guarded. Missing metadata falls back after five seconds, and an unresponsive launcher becomes a recoverable failure after fifteen seconds.

Failed launches, exceptions and missing configuration display an inline accessible message. Users can copy the message (including the subject/report metadata) or the configured support address. Clipboard errors retain the editable/selectable text. Leaving a nonempty draft asks for confirmation. Drafts are held in memory only: they are not added to app storage and cannot survive OS process termination. Users should copy before intentionally discarding or closing the application.

## Support email configuration

Edit **`lib/core/constants/support_config.dart`**:

```dart
static const supportEmail = 'YOUR_SUPPORT_EMAIL_HERE';
```

Replace only this value with your mailbox before release. The placeholder is intentionally not launchable; the feature shows an explanation and preserves feedback for copying. No real address was invented. The `developer@example.com` address in tests/captures is a reserved test fixture, not release configuration.

## Privacy and technical context

Problem reports append only:

- Fixed app name: FocusFlow.
- Actual installed app version from package metadata.
- Actual build number from package metadata.
- Platform category (`android`, `iOS`, another Flutter platform name, or `web`).

There is no repository access in the support service. No tasks, focus history, XP, achievements, settings, account identifiers, installation signatures, installer names, device IDs or telemetry are attached. The feature requests no new Android permissions and creates no feedback backend. Android OS release/device model are intentionally omitted: platform plus app/build provides useful basic context without adding a device-information dependency. The user may choose to describe their device or issue in the message.

## Architecture and dependencies

The screen manages ephemeral form state; `SupportEmailService` prepares immutable email drafts and isolates the external launcher/metadata boundaries for tests. No new Cubit, DI framework, global app service or persistence schema was needed.

Two direct runtime dependencies were added:

- `url_launcher ^6.3.2`: maintained Flutter email-client launching. Uses `mailto:` and external-application mode. URI query values use component encoding so Arabic, spaces, `+`, `&`, `#`, percentages and newlines survive. Direct launch avoids false-negative preflight queries.
- `package_info_plus ^10.2.1`: actual installed version/build instead of a duplicated hard-coded version. Its remaining package fields are ignored.

Their platform implementations/transitive dependencies are locked in pubspec.lock. Existing locked dependency versions were retained. Generated platform plugin registrants changed to register these packages. No launcher icon, native splash, application ID, notifications or signing policy was changed.

Package references: https://pub.dev/packages/url_launcher and https://pub.dev/packages/package_info_plus.

## Files

Created:

- `lib/core/constants/support_config.dart`
- `lib/core/services/support_email_service.dart`
- `lib/features/settings/ui/support_screen.dart`
- `test/features/settings/support_email_service_test.dart`
- `test/features/settings/support_screen_test.dart`
- This report, feature validation logs, changed-file manifest and six review captures.

Modified:

- `lib/features/settings/ui/settings_screen.dart`: support section, route guard and injectable service boundary for tests.
- `pubspec.yaml`, `pubspec.lock`: the two packages and required transitive dependencies.
- Generated iOS/Linux/macOS/Windows plugin registration files.
- README and CHANGELOG links describing this addition.

`docs/SUPPORT_CHANGED_FILES.txt` lists the exact differences from the reviewed archive. All pre-existing Dart files outside Settings were compared byte-for-byte with that archive and remained identical. The original review documentation/logs remain historical evidence; the results below apply to this feature release.

## Validation

| Check | Result |
| --- | --- |
| Dependency resolution | Passed |
| dart format / unchanged-format check | Passed: 57 files, zero formatting changes remaining |
| flutter analyze | Passed: No issues found |
| flutter test | Passed: **234 tests** (203 existing + 31 new) |
| New-screen capture run | Six phone-size captures plus keyboard/large-text cases; 21 new-feature widget tests passed with SDK fonts; all six captures reviewed |
| flutter build appbundle --release | Passed: exit 0; unsigned AAB, 54,588,770 bytes (54.6 MB); archive integrity verified |

The new tests cover Settings entry points and existing haptics, form validation, correct subjects/bodies, exact metadata allow-list, Arabic/URI encoding, contact, metadata failure, missing email configuration, launcher failure/exception/timeout, clipboard handoff, retained text, duplicate submission, discard confirmation, light/dark phone layouts and 320×640 with 150% text plus a 260-pixel keyboard inset. External email clients are faked; no email was sent during automated testing.

### Android build evidence

The final build completed successfully on September 29, 2026 with Flutter 3.47.2 / Dart 3.13.2 and JDK 17. Gradle completed in 670.1 seconds. A prior environment-interrupted attempt had no completed result; the successful final run is recorded in `docs/support-validation-logs/android_build_final.log`.

- Output: `build/app/outputs/bundle/release/app-release.aab`.
- Size: 54,588,770 bytes.
- SHA-256: `6b0b7cd6df596d1cda672ca5e6639d8598cdffebd296f64d27966b3001cd970f`.
- ZIP CRC check passed; no JAR signature entries were present, confirming the unsigned release output.
- The delivered ZIP contains the complete source project and evidence, excluding generated build outputs and SDK caches. Rebuild the AAB after configuring your support address and owner signing credentials.

## Physical Android acceptance

After setting your support address, test on your Redmi Note 11 Pro (and another supported Android version if available):

1. Settings section, all actions and app/system theme changes; TalkBack reading order, touch targets, large text, landscape and keyboard scrolling.
2. Gmail/another installed mail client: correct recipient, subject, Arabic/punctuation/newlines and a long message; manually review metadata before sending.
3. No enabled email handler: clear error, unchanged draft, copy message/address and retry. Cancelling in the email client must leave the in-app draft available.
4. Rapid taps, back/Close with a draft, Keep editing/Discard, background/resume. OS process death can discard this intentionally memory-only draft.
5. A signed internal-test build before store release. No production signing credentials are included. iOS/desktop compilation and physical-client behavior were not verified here.
