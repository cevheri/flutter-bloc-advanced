import 'dart:async';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

// The browser-only tests skip the global bootstrap in test/flutter_test_config.dart, which imports alchemist and does
// not compile for the web. They only get the logger the code under test writes to, as the app's entry points set it up.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppLogger.configure(isProduction: false);
  await testMain();
}
