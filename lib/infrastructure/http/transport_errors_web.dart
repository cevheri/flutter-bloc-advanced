/// Web build of the dart:io checks in `transport_errors.dart`: the browser never reports a dart:io error, so every
/// check is false.
///
/// This file deliberately avoids `dart:io` so web (JS and WASM) builds compile.
library;

bool isLostConnection(Object? error) => false;
