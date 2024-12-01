#!/bin/bash

echo "Running flutter clean"
flutter clean

echo "Running pub get"
flutter pub get

echo "Running build_runner"
dart run build_runner build --delete-conflicting-outputs
dart run intl_utils:generate

echo "Running flutter analyze"
flutter analyze
if [ $? -ne 0 ]; then
  echo "Flutter analyze found issues. Exiting."
  exit 1
fi

echo "Running flutter test"
flutter test --coverage
if [ $? -ne 0 ]; then
  echo "Flutter test found issues. Exiting."
  exit 1
fi

echo "Running flutter build apk"
flutter build apk --release --target lib/main/main_prod.dart

echo "Running flutter build appbundle"
flutter build appbundle --release --target lib/main/main_prod.dart
