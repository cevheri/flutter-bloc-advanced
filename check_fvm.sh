#!/bin/bash

fvm use 3.24.5

fvm flutter clean
fvm flutter pub get

fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run intl_utils:generate

# when flutter analyze issue found then exit
fvm flutter analyze
fvm flutter test --coverage

fvm flutter build apk --release --target lib/main/main_prod.dart
fvm flutter build appbundle --release --target lib/main/main_prod.dart
