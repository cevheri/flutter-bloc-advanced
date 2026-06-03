import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/core/security/screen_capture_protection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('screen_protector');

  final List<MethodCall> calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    ScreenCaptureProtection.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall call,
    ) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    ScreenCaptureProtection.resetForTesting();
  });

  group('ScreenCaptureProtection', () {
    test('isEnabled starts false', () {
      expect(ScreenCaptureProtection.isEnabled, isFalse);
    });

    test('enable() flips isEnabled true and invokes both Android + iOS protect calls', () async {
      await ScreenCaptureProtection.enable();
      expect(ScreenCaptureProtection.isEnabled, isTrue);
      final methods = calls.map((c) => c.method).toSet();
      expect(methods, containsAll(<String>{'protectDataLeakageOn', 'protectDataLeakageWithBlur'}));
    });

    test('enable() is idempotent: second call does not re-invoke plugin', () async {
      await ScreenCaptureProtection.enable();
      calls.clear();
      await ScreenCaptureProtection.enable();
      expect(calls, isEmpty);
      expect(ScreenCaptureProtection.isEnabled, isTrue);
    });

    test('disable() flips isEnabled false and invokes both off calls', () async {
      await ScreenCaptureProtection.enable();
      calls.clear();
      await ScreenCaptureProtection.disable();
      expect(ScreenCaptureProtection.isEnabled, isFalse);
      final methods = calls.map((c) => c.method).toSet();
      expect(methods, containsAll(<String>{'protectDataLeakageOff', 'protectDataLeakageWithBlurOff'}));
    });

    test('disable() is idempotent when already disabled: no plugin call', () async {
      await ScreenCaptureProtection.disable();
      expect(calls, isEmpty);
      expect(ScreenCaptureProtection.isEnabled, isFalse);
    });

    test('plugin error during enable() is swallowed; state still flips true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom');
      });
      await ScreenCaptureProtection.enable();
      expect(ScreenCaptureProtection.isEnabled, isTrue);
    });

    test('web override: enable() is a true no-op, no plugin call, isEnabled stays false', () async {
      ScreenCaptureProtection.debugWebOverride = true;
      await ScreenCaptureProtection.enable();
      expect(calls, isEmpty);
      expect(ScreenCaptureProtection.isEnabled, isFalse);
    });

    test('web override: disable() is also a no-op', () async {
      ScreenCaptureProtection.debugWebOverride = true;
      await ScreenCaptureProtection.disable();
      expect(calls, isEmpty);
      expect(ScreenCaptureProtection.isEnabled, isFalse);
    });

    test('nested leases: protection stays on until the last lease is released', () async {
      // Two protected screens mounted (e.g. A pushes B).
      await ScreenCaptureProtection.enable();
      await ScreenCaptureProtection.enable();
      expect(ScreenCaptureProtection.isEnabled, isTrue);

      // Inner screen disposed: still one lease held, protection must stay on.
      calls.clear();
      await ScreenCaptureProtection.disable();
      expect(calls, isEmpty);
      expect(ScreenCaptureProtection.isEnabled, isTrue);

      // Outer screen disposed: last lease released, protection turns off.
      await ScreenCaptureProtection.disable();
      expect(ScreenCaptureProtection.isEnabled, isFalse);
      final methods = calls.map((c) => c.method).toSet();
      expect(methods, containsAll(<String>{'protectDataLeakageOff', 'protectDataLeakageWithBlurOff'}));
    });
  });
}
