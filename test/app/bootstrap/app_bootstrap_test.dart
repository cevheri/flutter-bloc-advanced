@Tags(['widget'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('AppBootstrap.run', () {
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
