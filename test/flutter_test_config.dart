import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
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
  // testWidgets hands test() the binding's defaultTestTimeout, 10 minutes unless set here, and a test's own duration
  // replaces the timeout in dart_test.yaml. A factor of 1 keeps the configured timeout, as a plain test() does, so a
  // hung widget test fails after 30 seconds instead of holding CI for 10 minutes.
  AutomatedTestWidgetsFlutterBinding.instance.defaultTestTimeout = const Timeout.factor(1);
  AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  EquatableConfig.stringify = true;
  registerAllFallbackValues();

  // Per-test in every file, opted out or not. rootBundle caches the Future of
  // each string asset, such as the assets/mock/*.json that MockInterceptor
  // serves, and code awaiting that Future is resumed by a microtask of the
  // zone that created it. When a testWidgets body loaded the asset, that is
  // the test's FakeAsync zone, whose microtasks nothing runs after the test,
  // so a later testWidgets in the same file waited for that asset forever.
  // Clearing after each test too keeps such a Future from reaching a later
  // group's setUpAll or a tearDownAll.
  setUp(rootBundle.clear);
  tearDown(rootBundle.clear);

  // Per-test, unless a file opts out.
  setUp(() async {
    if (TestEnv.autoReset) await TestEnv.reset();
  });
  tearDown(() async {
    if (TestEnv.autoReset) await TestEnv.reset();
  });

  // Golden tests (alchemist) render under the project light theme by default;
  // dark-theme scenarios wrap their child in AppTheme.dark() explicitly.
  // Platform goldens are disabled so only the CI (Ahem-rendered) variant runs —
  // identical output on macOS/Linux/CI, no font-rendering flake.
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: AppTheme.light(),
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
