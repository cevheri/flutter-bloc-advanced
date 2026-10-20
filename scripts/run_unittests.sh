#!/bin/bash
set -e

#dart pub global activate fvm
#export PATH="$PATH":"$HOME/.pub-cache/bin"
fvm use 3.47.7

fvm flutter clean
fvm flutter pub get

fvm dart run intl_utils:generate
# intl_utils formats its output at 80 columns; reformat to 120 so the committed files stay unchanged
fvm dart format lib/generated --line-length=120

# when flutter analyze issue found then exit
if ! fvm dart analyze; then
  echo "Flutter analyze found issues. Exiting."
  exit 1
fi

if ! fvm flutter test --coverage; then
  echo "Flutter test found issues. Exiting."
  exit 1
fi