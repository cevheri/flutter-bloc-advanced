#!/bin/bash
set -e

echo "Running flutter clean"
fvm flutter clean

echo "Running pub get"
fvm flutter pub get

echo "Running build_runner"
fvm dart run intl_utils:generate
# intl_utils formats its output at 80 columns; reformat to 120 so the committed files stay unchanged
fvm dart format lib/generated --line-length=120

echo "Running flutter analyze"
if ! fvm dart analyze; then
  echo "Flutter analyze found issues. Exiting."
  exit 1
fi

echo "Running flutter test"
if ! fvm flutter test --coverage; then
  echo "Flutter test found issues. Exiting."
  exit 1
fi

echo "Running flutter build apk"
fvm flutter build apk --release --target lib/main/main_prod.dart

echo "Running flutter build appbundle"
fvm flutter build appbundle --release --target lib/main/main_prod.dart
