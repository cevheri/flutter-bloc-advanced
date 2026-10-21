import 'package:flutter_bloc_advance/app/bootstrap/sentry_start.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/core/analytics/log_analytics_service.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/sentry_analytics_service.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
// ignore: implementation_imports
import 'package:sentry/src/platform/platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const _dsn = 'https://public@example.invalid/1';

const _prodWithDsn = AppConfig(
  environment: Environment.prod,
  apiBaseUrl: 'https://api.example.invalid',
  certificatePins: [],
  idleTimeout: null,
  sentryDsnDefine: _dsn,
);

/// The platform sentry_flutter reports on an Android device, where it picks its Java binding.
class _AndroidPlatform extends Platform {
  const _AndroidPlatform();

  @override
  OperatingSystem get operatingSystem => OperatingSystem.android;
}

/// Records each SentryFlutter.init call instead of starting the SDK.
class _InitCalls {
  final options = <SentryFlutterOptions>[];
  final runners = <AppRunner?>[];

  Future<void> call(FlutterOptionsConfiguration configure, {AppRunner? appRunner}) async {
    final flutterOptions = SentryFlutterOptions(platform: const _AndroidPlatform());
    await configure(flutterOptions);
    options.add(flutterOptions);
    runners.add(appRunner);
  }
}

void main() {
  group('SentryStart.gate', () {
    test('keeps the config when the host app started the native SDK', () async {
      final start = SentryStart(isNativeSdkReady: () async => true);

      final config = await start.gate(_prodWithDsn);

      expect(config.sentryDsn, _dsn);
      expect(const AppDependencies(appConfig: _prodWithDsn).createAnalyticsService(), isA<SentryAnalyticsService>());
    });

    // A release build whose host did not start the native SDK runs as without a DSN: no Dart SDK, and the log
    // analytics service, so no analytics event goes into a hub that never started.
    test('drops the DSN when the native SDK check keeps Sentry off', () async {
      final start = SentryStart(isNativeSdkReady: () async => false);

      final config = await start.gate(_prodWithDsn);

      expect(config.sentryDsn, isNull);
      expect(config.environment, Environment.prod);
      expect(config.apiBaseUrl, _prodWithDsn.apiBaseUrl);
      expect(AppDependencies(appConfig: config).createAnalyticsService(), isA<LogAnalyticsService>());
    });

    test('does not ask the host when there is no DSN', () async {
      var asked = false;
      final start = SentryStart(
        isNativeSdkReady: () async {
          asked = true;
          return true;
        },
      );

      final config = await start.gate(const AppConfig.prod());

      expect(config.sentryDsn, isNull);
      expect(asked, isFalse);
    });
  });

  group('SentryStart.run', () {
    test('skips SentryFlutter.init and runs the app when the native SDK check keeps Sentry off', () async {
      final init = _InitCalls();
      final start = SentryStart(isNativeSdkReady: () async => false, sentryInit: init.call);
      var ran = 0;

      final config = await start.gate(_prodWithDsn);
      await start.run(config.sentryDsn, release: '1.0.0+1', appRunner: () => ran++);

      expect(init.options, isEmpty);
      expect(ran, 1);
    });

    test('starts SentryFlutter with the app as its runner when there is a DSN', () async {
      final init = _InitCalls();
      final start = SentryStart(isNativeSdkReady: () async => true, sentryInit: init.call);
      var ran = 0;

      await start.run(_dsn, release: '1.0.0+1', appRunner: () => ran++);

      expect(init.options, hasLength(1));
      await init.runners.single!();
      expect(ran, 1);
    });
  });

  group('configureSentryOptions', () {
    test('on Android leaves the native SDK to the host app and installs both scrubbers', () {
      final options = SentryFlutterOptions(platform: const _AndroidPlatform());

      configureSentryOptions(options, dsn: _dsn, release: '1.0.0+1');

      expect(options.autoInitializeNativeSdk, isFalse);
      expect(options.beforeSend, isNotNull);
      expect(options.beforeBreadcrumb, isNotNull);
      expect(options.enablePrintBreadcrumbs, isFalse);
      expect(options.dsn, _dsn);
      expect(options.release, '1.0.0+1');
      expect(options.tracesSampleRate, 0.2);
    });

    test('installs a beforeSend that masks an email and a beforeBreadcrumb that masks one', () async {
      final options = SentryFlutterOptions(platform: const _AndroidPlatform());

      configureSentryOptions(options, dsn: _dsn, release: '1.0.0+1');
      final event = await options.beforeSend!(SentryEvent(message: SentryMessage('jane.doe@example.com')), Hint());
      final crumb = options.beforeBreadcrumb!(Breadcrumb(message: 'jane.doe@example.com'), Hint());

      expect(event!.message!.formatted, '[REDACTED_EMAIL]');
      expect(crumb!.message, '[REDACTED_EMAIL]');
    });
  });
}
