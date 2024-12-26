#!/bin/bash

fvm use 3.27.1

echo "Running flutter clean"
fvm flutter clean

echo "Running pub get"
fvm flutter pub get

echo "Running build_runner"
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run intl_utils:generate

echo "Running flutter analyze"
fvm flutter analyze
if [ $? -ne 0 ]; then
  echo "Flutter analyze found issues. Exiting."
  exit 1
fi

echo "Running flutter test"
fvm flutter test --coverage
if [ $? -ne 0 ]; then
  echo "Flutter test found issues. Exiting."
  exit 1
fi

echo "Running flutter build apk"
fvm flutter build apk --release --target lib/main/main_prod.dart

echo "Running flutter build appbundle"
fvm flutter build appbundle --release --target lib/main/main_prod.dart
