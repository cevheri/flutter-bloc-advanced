#!/bin/bash
set -e

fvm use 3.47.7

echo "Running flutter clean"
fvm flutter clean

echo "Running pub get"
fvm flutter pub get

echo "Running intl_utils"
fvm dart run intl_utils:generate

echo dart fix --apply
fvm dart fix --apply

echo dart format . --line-length=120
fvm dart format . --line-length=120

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
