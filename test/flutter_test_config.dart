import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mock_classes.dart';
import 'support/test_env.dart';

/// Global test bootstrap, auto-discovered by `flutter test` for everything
/// under `test/`. Runs one-time config per isolate and an automatic per-test
/// environment reset. Files that manage the secure-storage MethodChannel
/// themselves opt out via `setUpAll(() => TestEnv.autoReset = false);`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // One-time per isolate.
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  EquatableConfig.stringify = true;
  registerAllFallbackValues();

  // Per-test, unless a file opts out.
  setUp(() async {
    if (TestEnv.autoReset) await TestEnv.reset();
  });
  tearDown(() async {
    if (TestEnv.autoReset) await TestEnv.reset();
  });

  await testMain();
}
