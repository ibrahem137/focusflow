# Validation — September 27, 2026

Flutter **3.47.2**, Dart **3.13.2**, Linux x64; full Eclipse Temurin JDK 17 and Android SDK 36 for the native build. Dependencies resolved against the supplied lockfile; no runtime package upgrade was requested. The platform-interface test dependency was already transitively present.

The environment ran the official Flutter tool entrypoint through its Dart snapshot, with CI/analytics suppression. The commands below are the equivalent normal developer commands. Build tools used the environment proxy and its existing trusted certificates. No certificate verification was disabled.

| Check | Initial upload | Final project |
| --- | --- | --- |
| flutter pub get | Passed; six newer packages outside constraints | Passed (offline cache on resumed review) |
| dart format --output=none --set-exit-if-changed . | Splash formatting drift | Passed: 52 files, 0 changed |
| flutter analyze --no-pub | No issues found | No issues found |
| flutter test --no-pub | 116 passed, 6 failed | **203 passed** |
| Review capture run | Not applicable | **108 passed**, 36 phone-size PNGs generated |
| flutter build appbundle --release --no-pub | First attempt lacked javac | **Passed**, exit 0; unsigned AAB, 54.3 MB |

Final logs are in `docs/validation-logs`. A test failure in the baseline is not presented as a current failure. The first final analyzer run found one braces-style info; it was corrected and analysis rerun cleanly. All final tests were rerun after the final source edits.

## Coverage

Critical coverage includes task creation/editing/completion/claim/deletion, concurrent actions, reward receipts, focus pause/resume/restart/deadline reconciliation, retry after storage failure, reset semantics, settings persistence/permission races, achievements, streak boundaries and corruption preservation. Startup is tested with delayed/failed initialization and reduced motion. The edit dialog is exercised at 320×640 with a 280-pixel keyboard inset.

The 108 layout cases cover nine screens × light/dark × three viewport/text-scale combinations × empty/populated data. Populated fixtures contain long task titles/categories, 50 sessions and earned progress. All four onboarding pages are covered by progression tests; the screen matrix captures its initial page. Tests do not establish real-device frame rate or OS notification delivery.

Review captures under `test/flows/goldens` are date-dependent human-review images, not default pixel-comparison gates. SDK font loading makes most text readable; some fallback/emoji glyphs remain limited by the Linux test environment. The splash capture includes its end-of-frame reveal. Dark empty screens and light populated screens were visually inspected, along with the completed splash artwork.

## Limits

Android release compilation is distinct from device testing and owner signing. iOS/Xcode, desktop release builds and physical hardware tests were not performed. No fresh web release build is claimed for this review. See RELEASE.md for remaining native delivery, background/lock/process-kill, accessibility, signing and store checks.

## Native artifact verification

Produced `build/app/outputs/bundle/release/app-release.aab` (54,317,583 bytes). SHA-256: `69e4f9ba2fcf2d62ac14cf6a3ed1a64fb1ea1fdaba2a9e99b1de0a4c42074e7b`. Archive CRC validation passed; there are no signing entries, consistent with the absence of owner credentials. Flutter's final native-symbol check passed. This source ZIP omits generated build artifacts; rebuild and sign with your own upload key.

Environment-only retries resolved a missing javac, JDK trust-store configuration, nested SDK extraction paths and the command-line tools location required by Flutter's AAB checker. No app workaround bypasses native-symbol validation. The successful cached final build ran Gradle in 15.2 seconds; this is not a clean-build performance benchmark.
