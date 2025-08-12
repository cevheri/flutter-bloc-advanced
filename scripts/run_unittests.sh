#!/bin/bash

#dart pub global activate fvm
#export PATH="$PATH":"$HOME/.pub-cache/bin"
fvm use 3.27.1

fvm flutter clean
fvm flutter pub get

fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run intl_utils:generate

# when flutter analyze issue found then exit
fvm flutter analyze
if [ $? -ne 0 ]; then
  echo "Flutter analyze found issues. Exiting."
  exit 1
fi

fvm flutter test --coverage
if [ $? -ne 0 ]; then
  echo "Flutter test found issues. Exiting."
  exit 1
fi