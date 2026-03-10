#!/bin/bash

#dart pub global activate fvm
#export PATH="$PATH":"$HOME/.pub-cache/bin"
fvm use 3.41.4

fvm flutter clean
fvm flutter pub get

fvm dart run intl_utils:generate

# when flutter analyze issue found then exit
fvm dart analyze
if [ $? -ne 0 ]; then
  echo "Flutter analyze found issues. Exiting."
  exit 1
fi

fvm flutter test --coverage
if [ $? -ne 0 ]; then
  echo "Flutter test found issues. Exiting."
  exit 1
fi