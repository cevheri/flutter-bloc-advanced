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

# Download SonarQube scanner
SONAR_SCANNER_VERSION=6.2.1.4610
SONAR_SCANNER_DIR=$HOME/.sonar/sonar-scanner-$SONAR_SCANNER_VERSION-linux-x64
SONAR_SCANNER_ZIP=$SONAR_SCANNER_DIR.zip

if [ ! -d "$SONAR_SCANNER_DIR" ]; then
  echo "Downloading SonarQube scanner..."
  curl --create-dirs -sSLo $SONAR_SCANNER_ZIP https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_SCANNER_VERSION-linux-x64.zip
  unzip -o $SONAR_SCANNER_ZIP -d $HOME/.sonar/
fi

# Set up environment variables
export PATH=$SONAR_SCANNER_DIR/bin:$PATH

# Run SonarQube scanner
$SONAR_SCANNER_DIR/bin/sonar-scanner \
  -Dsonar.projectKey=cevheri_flutter-bloc-advanced \
  -Dsonar.organization=cevheri-open-source \
  -Dsonar.sources=. \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.login=$SONAR_TOKEN