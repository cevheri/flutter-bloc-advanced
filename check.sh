#!/bin/bash

fvm flutter clean
fvm flutter pub get

fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run intl_utils:generate

fvm flutter analyze
fvm flutter test --coverage

fvm flutter build apk --release --target lib/main/main_prod.dart
fvm flutter build appbundle --release --target lib/main/main_prod.dart

#sonar coverage

#docker run --rm -it -v ${PWD}:/build --workdir /build ghcr.io/cirruslabs/flutter:stable flutter test