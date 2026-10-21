import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/native_sentry_start.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:sentry/src/platform/platform.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The platform sentry_flutter reports on an Android device, where it picks its Java binding.
class _AndroidPlatform extends Platform {
  const _AndroidPlatform();

  @override
  OperatingSystem get operatingSystem => OperatingSystem.android;
}

/// The platform sentry_flutter reports in a browser on an Android phone.
class _BrowserOnAndroidPlatform extends _AndroidPlatform {
  const _BrowserOnAndroidPlatform();

  @override
  bool get isWeb => true;
}

void main() {
  group('configureNativeSdkStart', () {
    test('turns the native auto-init off where the host app starts the native SDK', () {
      final options = SentryFlutterOptions();

      configureNativeSdkStart(options, hostStarts: true);

      expect(options.autoInitializeNativeSdk, isFalse);
    });

    test('keeps the native auto-init on where sentry_flutter starts the native SDK', () {
      final options = SentryFlutterOptions();

      configureNativeSdkStart(options, hostStarts: false);

      expect(options.autoInitializeNativeSdk, isTrue);
    });

    test('reads Android from the platform of the options', () {
      final options = SentryFlutterOptions(platform: const _AndroidPlatform());

      configureNativeSdkStart(options);

      expect(hostStartsNativeSdk(options), isTrue);
      expect(options.autoInitializeNativeSdk, isFalse);
    });

    test('keeps the native auto-init on in a browser on Android', () {
      final options = SentryFlutterOptions(platform: const _BrowserOnAndroidPlatform());

      configureNativeSdkStart(options);

      expect(hostStartsNativeSdk(options), isFalse);
      expect(options.autoInitializeNativeSdk, isTrue);
    });

    // The test host is Linux, where sentry_flutter starts sentry-native itself, as it does on iOS and macOS.
    test('reads the platform of the options when the caller does not say', () {
      final options = SentryFlutterOptions();

      configureNativeSdkStart(options);

      expect(hostStartsNativeSdk(options), isFalse);
      expect(options.autoInitializeNativeSdk, isTrue);
    });
  });

  group('hostStartsNativeSdkOn', () {
    test('is true on Android', () {
      expect(hostStartsNativeSdkOn(isWeb: false, isAndroid: true), isTrue);
    });

    // On web the options report the operating system of the browser, Android in a phone browser, and the flag
    // controls the JavaScript SDK.
    test('is false in a browser on Android, where sentry_flutter starts the JavaScript SDK', () {
      expect(hostStartsNativeSdkOn(isWeb: true, isAndroid: true), isFalse);
    });

    test('is false on every other platform', () {
      expect(hostStartsNativeSdkOn(isWeb: false, isAndroid: false), isFalse);
      expect(hostStartsNativeSdkOn(isWeb: true, isAndroid: false), isFalse);
    });
  });

  group('nativeSdkReady', () {
    const channel = MethodChannel(nativeSentryChannelName);
    late List<String> calls;
    late Object? answer;

    setUp(() {
      calls = [];
      answer = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return answer;
      });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
      );
    });

    test('does not ask the host where sentry_flutter starts the native SDK', () async {
      expect(await nativeSdkReady(hostStarts: false), isTrue);
      expect(calls, isEmpty);
    });

    test('lets the Dart SDK start when the host app started the native SDK', () async {
      expect(await nativeSdkReady(hostStarts: true), isTrue);
      expect(calls, ['isEnabled']);
    });

    test('throws a StateError that names the mismatch in a debug or profile build', () async {
      answer = false;

      await expectLater(
        nativeSdkReady(hostStarts: true, releaseMode: false),
        throwsA(isA<StateError>().having((error) => error.message, 'message', contains('main_prod.dart'))),
      );
    });

    // A fork or a headless engine without the channel, or a host whose handler fails, must not crash a release start.
    for (final (name, handler) in [
      ('does not answer on the channel', null),
      ('fails to answer', (MethodCall call) async => throw PlatformException(code: 'boom', message: 'secret detail')),
    ]) {
      test('throws a StateError in a debug or profile build when the host app $name', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, handler);

        await expectLater(
          nativeSdkReady(hostStarts: true, releaseMode: false),
          throwsA(isA<StateError>().having((error) => error.message, 'message', contains('main_prod.dart'))),
        );
      });

      test('logs and keeps the Dart SDK off in a release build when the host app $name', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, handler);
        final printed = <String>[];

        final ready = await runZoned(
          () => nativeSdkReady(hostStarts: true, releaseMode: true),
          zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) => printed.add(line)),
        );

        expect(ready, isFalse);
        expect(printed.join('\n'), allOf(contains('Sentry stays off'), isNot(contains('secret detail'))));
      });
    }

    test('logs the mismatch and keeps the Dart SDK off in a release build', () async {
      answer = false;
      final printed = <String>[];

      final ready = await runZoned(
        () => nativeSdkReady(hostStarts: true, releaseMode: true),
        zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) => printed.add(line)),
      );

      expect(ready, isFalse);
      expect(printed.join('\n'), contains('the host app did not start the native Sentry SDK'));
    });
  });
}
