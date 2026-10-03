#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CI=true FLUTTER_SUPPRESS_ANALYTICS=true
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build appbundle --release
