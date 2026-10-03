# Release handoff — September 27, 2026

Use Flutter 3.47.2 / Dart 3.13.2, a full JDK 17, Android SDK 36/build-tools 36.0.0 and NDK 28.2.13676358. A JRE without javac cannot compile the Android app. See VALIDATION.md for the actual build result.

## Signing and identifiers

The Android package/namespace is **com.ibrahemalhuossien.focusflow**, preserved from this upload. Do not change it for an update to the same installed app. The iOS project retains its supplied identifiers; check them with your Apple account separately.

1. Keep your existing upload keystore outside the source repository. This review creates no credentials.
2. Copy `android/key.properties.example` to `android/key.properties`, then fill in your real alias, passwords and keystore path. `storeFile` resolves relative to the `android` directory unless absolute. These private files are gitignored.
3. Run `flutter pub get`, `flutter analyze`, `flutter test`, then `flutter build appbundle --release`.
4. The AAB is written to `build/app/outputs/bundle/release/app-release.aab`. Without key.properties this project builds an **unsigned** bundle; it is not a Play-uploadable production-signed release. There is no debug-key fallback.
5. Set the next unused version code in pubspec.yaml before uploading. The supplied value remains `1.0.0+1`.
6. Validate the signed bundle on a Play internal track and install through that track before rollout. Supply listing text, screenshots, icon acceptance, privacy/data-safety declarations and your Play Console configuration.

## Required physical Android checks

- Cold and warm launch on Android 12+ and an older supported OS: continuous dark background, no overlay hiding the start of the clock/leaf animation, first-launch onboarding, returning-user Home. Check launcher icon cropping under circular/squircle masks.
- All four onboarding pages: swipe, rapid Next, Skip/Get Started, restart persistence, reduced motion, landscape and enlarged text.
- Task create/edit/complete/claim/delete, long and Arabic titles, keyboard scrolling, repeated taps and restart after reward. Editing must preserve the original reward.
- Start/pause/resume/cancel a timer, switch tabs, lock the device, background it and terminate the process. Reopen before/after the deadline. Confirm one session and one reward, correct paused time, and reset while running.
- Reminder permission denied/allowed/revoked, enable then immediately disable, daily-time changes, full reset during a permission prompt, reboot, device date/time/timezone changes, and completing focus before a streak reminder. Check for cancellation and duplicates.
- TalkBack labels/order, large text, light/dark/system theme switching, haptic/audio preferences and OEM emoji rendering.
- A large real history and a constrained device: profile cold start, frame timing and memory. No device performance numbers were measured here.

Android reminders are inexact and subject to OS battery policy. Force-stopping can suppress delivery until reopening. Completion sound/haptics are in-app feedback; this app does not promise an OS background timer-completion alarm. Timestamp reconciliation occurs when execution resumes.

## Other platforms

Core Flutter targets remain included. Native reminder code supports Android/iOS; unsupported platforms explain and disable reminder switches. iOS still needs an Xcode archive, Apple team/certificates and physical notification tests. Desktop and iOS release compilation were not verified during this review.

## Reproducing review images

```sh
flutter test test/flows/responsive_screens_test.dart --dart-define=CAPTURE_GOLDENS=true --update-goldens
```

For readable review text, also pass `--dart-define=REVIEW_FONT=/absolute/path/to/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf`. Captures are in `test/flows/goldens`; normal tests check layout without date-dependent pixel comparison. Missing emoji in the Linux test-font environment is a capture limitation, not evidence of device rendering.
