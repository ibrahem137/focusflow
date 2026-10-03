$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
dart format --output=none --set-exit-if-changed .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter build appbundle --release
exit $LASTEXITCODE
