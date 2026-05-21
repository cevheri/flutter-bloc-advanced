import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the `throw-on-failure` contract documented on [ISecureStorage]
/// against the production [FlutterSecureStorageAdapter]. The other
/// storage tests use an in-memory fake that cannot fail, so a future
/// "helpful" refactor that catches and returns null inside the adapter
/// would silently break rollback semantics in
/// [AuthSessionRepositoryImpl.persist] and [SessionMigration] without
/// any test surface noticing.
///
/// We drive the underlying `plugins.it_nomads.com/flutter_secure_storage`
/// MethodChannel directly to simulate a platform error.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mockChannel(Future<Object?> Function(MethodCall) handler) {
    messenger.setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('FlutterSecureStorageAdapter throw-on-failure contract', () {
    test('read propagates PlatformException from the platform side', () async {
      mockChannel((call) async {
        if (call.method == 'read') {
          throw PlatformException(code: 'platform_error', message: 'decryption failed');
        }
        return null;
      });

      final adapter = FlutterSecureStorageAdapter();

      await expectLater(
        adapter.read('jwtToken'),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'platform_error')),
      );
    });

    test('write propagates PlatformException from the platform side', () async {
      mockChannel((call) async {
        if (call.method == 'write') {
          throw PlatformException(code: 'platform_error', message: 'keystore unavailable');
        }
        return null;
      });

      final adapter = FlutterSecureStorageAdapter();

      await expectLater(adapter.write('jwtToken', 'some-token'), throwsA(isA<PlatformException>()));
    });

    test('delete propagates PlatformException from the platform side', () async {
      mockChannel((call) async {
        if (call.method == 'delete') {
          throw PlatformException(code: 'platform_error', message: 'access denied');
        }
        return null;
      });

      final adapter = FlutterSecureStorageAdapter();

      await expectLater(adapter.delete('jwtToken'), throwsA(isA<PlatformException>()));
    });

    test('deleteAll propagates PlatformException from the platform side', () async {
      mockChannel((call) async {
        if (call.method == 'deleteAll') {
          throw PlatformException(code: 'platform_error', message: 'cleanup failed');
        }
        return null;
      });

      final adapter = FlutterSecureStorageAdapter();

      await expectLater(adapter.deleteAll(), throwsA(isA<PlatformException>()));
    });

    test('read returns null only when the key is absent (not on error)', () async {
      mockChannel((call) async {
        expect(call.method, 'read');
        return null; // absent
      });

      final adapter = FlutterSecureStorageAdapter();

      expect(await adapter.read('jwtToken'), isNull);
    });
  });
}
