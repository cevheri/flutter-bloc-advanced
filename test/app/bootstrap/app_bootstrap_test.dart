@Tags(['widget'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap_config.dart';
import 'package:flutter_bloc_advance/app/bootstrap/sentry_start.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Records what AppBootstrap.run asks of the Sentry start, answers the gate with [gated], and starts nothing.
class _RecordingSentryStart implements SentryStart {
  _RecordingSentryStart(this.gated);

  final AppConfig gated;
  final gatedConfigs = <AppConfig>[];
  final runDsns = <String?>[];

  @override
  Future<bool> Function() get isNativeSdkReady => throw UnimplementedError();

  @override
  SentryInit get sentryInit => throw UnimplementedError();

  @override
  Future<AppConfig> gate(AppConfig config) async {
    gatedConfigs.add(config);
    return gated;
  }

  @override
  Future<void> run(String? dsn, {required String release, required AppRunner appRunner}) async => runDsns.add(dsn);
}

void main() {
  group('AppBootstrap.run', () {
    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'app',
        packageName: 'app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    // The gate decides before anything reads the config, so a release build whose host did not start the native SDK
    // runs as without a DSN, and the DSN SentryFlutter starts with is the one the gate kept.
    testWidgets('passes its config through the Sentry gate and starts Sentry with the DSN the gate kept', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async => ['none'],
      );
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
        MockStreamHandler.inline(onListen: (arguments, events) {}),
      );
      final sentry = _RecordingSentryStart(
        const AppConfig(
          environment: Environment.prod,
          apiBaseUrl: null,
          certificatePins: [],
          idleTimeout: null,
          sentryDsnDefine: 'https://public@example.invalid/1',
        ),
      );
      final flutterErrorHandler = FlutterError.onError;
      final platformErrorHandler = PlatformDispatcher.instance.onError;
      final observer = Bloc.observer;

      await tester.runAsync(
        () => AppBootstrap.run(const AppBootstrapConfig(environment: Environment.test), sentry: sentry),
      );
      FlutterError.onError = flutterErrorHandler;
      PlatformDispatcher.instance.onError = platformErrorHandler;
      Bloc.observer = observer;

      expect(sentry.gatedConfigs.map((config) => config.environment), [Environment.test]);
      expect(sentry.runDsns, ['https://public@example.invalid/1']);
    });

    testWidgets('leaves the language unstored on a first start, so the app follows the configured default', (
      tester,
    ) async {
      PackageInfo.setMockInitialValues(
        appName: 'app',
        packageName: 'app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async => ['none'],
      );
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
        MockStreamHandler.inline(onListen: (arguments, events) {}),
      );
      final flutterErrorHandler = FlutterError.onError;
      final platformErrorHandler = PlatformDispatcher.instance.onError;
      final observer = Bloc.observer;

      await tester.runAsync(() => AppBootstrap.run(const AppBootstrapConfig(environment: Environment.test)));
      // The crash reporter and the bloc observer are global; the test binding needs its own error handler back.
      FlutterError.onError = flutterErrorHandler;
      PlatformDispatcher.instance.onError = platformErrorHandler;
      Bloc.observer = observer;

      expect(await AppLocalStorage().read(StorageKeys.language.key), isNull);
    });
  });
}
