# FocusFlow

**Make room for focus.**

A local-first productivity app built with Flutter for meaningful tasks,
deep-focus sessions, progress tracking, achievements, and a growing
focus garden.

**[Website](https://focusflow-cf64f.web.app) · [Privacy
Policy](https://focusflow-cf64f.web.app/privacy/) ·
[Support](https://focusflow-cf64f.web.app/support/)**

------------------------------------------------------------------------

## About

FocusFlow is a privacy-focused productivity application designed to help
you organize meaningful work, stay focused, and visualize your progress.

The app is local-first: your productivity data stays on your device.
FocusFlow does not require an account, backend server, or cloud storage
to provide its core functionality.

## Features

-   Task management and completion tracking
-   Focus timer with 15, 25, 45, and 60-minute sessions
-   Persistent focus sessions resilient to app backgrounding and
    restarts
-   XP and level progression
-   Focus garden that grows through completed sessions
-   Productivity statistics and charts
-   Achievements and rewards
-   Local reminders and notifications
-   Light and dark themes
-   Onboarding experience
-   In-app feedback and support
-   Local-first data storage
-   Privacy-focused Android configuration

## Focus & Rewards

Completed focus sessions award **2 XP per minute**.

Tasks become eligible for **Claim XP** after completion. Reward claims
are persisted so the same reward cannot be claimed repeatedly.

Only successfully completed focus sessions contribute to the focus
garden.

The focus timer stores its end timestamp, allowing an active session to
remain accurate when the app is backgrounded or restarted.

## Privacy

FocusFlow is designed around a local-first privacy model.

The release build does not require general Internet access for its core
productivity functionality. User productivity data remains on the
device, and Android application backup is disabled.

The Android release is configured without permissions for:

-   Camera
-   Microphone
-   Location
-   Contacts
-   Advertising ID
-   Media or general storage access
-   Exact alarms

The app uses notification and boot-completion permissions to support
local reminders.

Read the full [Privacy
Policy](https://focusflow-cf64f.web.app/privacy/).

## Architecture

FocusFlow uses a feature-oriented Flutter structure with
BLoC/Cubit-based state management.

Main source areas include:

``` text
lib/
├── core/
└── features/
    ├── achievements/
    ├── focus/
    ├── garden/
    ├── home/
    ├── onboarding/
    ├── progress/
    ├── settings/
    ├── splash/
    ├── stats/
    └── tasks/
```

For additional architecture details, see
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Tech Stack

-   Flutter
-   Dart
-   flutter_bloc
-   shared_preferences
-   fl_chart
-   url_launcher
-   package_info_plus

The current release was validated with:

-   Flutter 3.47.2
-   Dart 3.13.2

Compatible newer Flutter versions may also work.

## Getting Started

### Requirements

Install Flutter and verify your environment:

``` bash
flutter doctor
```

Clone the repository:

``` bash
git clone https://github.com/ibrahem137/focusflow
cd focus_flow
```

Install dependencies:

``` bash
flutter pub get
```

Run the application:

``` bash
flutter run
```

Machine-specific SDK paths, signing credentials, generated build output,
and local Flutter configuration files are intentionally excluded from
the repository.

## Android Signing

Real Android signing credentials are **not included** in this
repository.

A safe template is provided at:

``` text
android/key.properties.example
```

Copy it locally to:

``` text
android/key.properties
```

Then replace the placeholder values with your own signing configuration.

Never commit your real `key.properties`, keystore, or signing passwords.

## Validation

FocusFlow includes validation scripts for Windows and Unix-like systems.

### Windows

``` powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\validate.ps1
```

### macOS / Linux

``` bash
bash tool/validate.sh
```

The validation pipeline runs:

``` text
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build appbundle --release
```

For version `1.0.0+1`, the final validation completed with:

-   58 Dart files formatted with no changes required
-   0 Flutter analyzer issues
-   248 passing tests
-   Successful Android App Bundle release build

See [docs/VALIDATION.md](docs/VALIDATION.md) for additional validation
details.

## Building

Build an Android App Bundle:

``` bash
flutter build appbundle --release
```

Build an Android APK:

``` bash
flutter build apk --release
```

Release signing requires your own local signing configuration.

## Documentation

-   [Architecture](docs/ARCHITECTURE.md)
-   [Production Review](docs/PRODUCTION_REVIEW.md)
-   [Validation](docs/VALIDATION.md)
-   [Release Guide](docs/RELEASE.md)
-   [Support & Feedback](docs/SUPPORT_FEEDBACK.md)
-   [Changelog](CHANGELOG.md)

## Contributing

Contributions, bug reports, and improvement ideas are welcome.

1.  Fork the repository.
2.  Create a feature branch.
3.  Make your changes.
4.  Run the validation suite.
5.  Submit a pull request.

Please avoid committing generated files, machine-specific configuration,
signing credentials, secrets, or private user data.

## Support

For feedback, bug reports, or questions:

**supportfocusflow3@gmail.com**

Visit the [FocusFlow Support
page](https://focusflow-cf64f.web.app/support/).

## License

FocusFlow is open-source software licensed under the [MIT
License](LICENSE).

Copyright © 2026 Ibrahem Alhuossien.
