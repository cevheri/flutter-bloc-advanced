import 'package:flutter/foundation.dart';
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

  /// The darwin plugin builds each keychain query from the `options` map
  /// sent with the call, so these maps are what the adapter applies on
  /// iOS and macOS.
  group('FlutterSecureStorageAdapter keychain options', () {
    /// Runs every adapter operation as if on [platform] and returns the
    /// `options` map that each call sent.
    Future<List<Map<Object?, Object?>>> optionsSentOn(TargetPlatform platform) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final sent = <Map<Object?, Object?>>[];
      mockChannel((call) async {
        sent.add((call.arguments as Map<Object?, Object?>)['options']! as Map<Object?, Object?>);
        return null;
      });

      final adapter = FlutterSecureStorageAdapter();
      await adapter.write('jwtToken', 'some-token');
      await adapter.read('jwtToken');
      await adapter.delete('jwtToken');
      await adapter.deleteAll();

      return sent;
    }

    // The template's macOS build is signed ad hoc, without the provisioning
    // profile that the data protection keychain's entitlement needs, so a
    // query that only that keychain can answer fails with
    // errSecMissingEntitlement (-34018). With an accessibility level set,
    // the plugin retries a lookup that found nothing with such a query.
    test('on macOS every call uses the login keychain and sends no accessibility level', () async {
      final sent = await optionsSentOn(TargetPlatform.macOS);

      expect(sent, hasLength(4));
      expect(sent, everyElement(containsPair('usesDataProtectionKeychain', 'false')));
      expect(sent, everyElement(isNot(contains('accessibility'))));
    });

    test('on iOS every call keeps accessibility first_unlock_this_device', () async {
      final sent = await optionsSentOn(TargetPlatform.iOS);

      expect(sent, hasLength(4));
      expect(sent, everyElement(containsPair('accessibility', 'first_unlock_this_device')));
    });
  });

  group('access token expiry', () {
    test('the OIDC keys keep their stored names', () {
      expect(SecureStorageKeys.oidcIdToken.key, 'oidcIdToken');
      expect(SecureStorageKeys.accessTokenExpiresAt.key, 'accessTokenExpiresAt');
    });

    test('an expiry round-trips through encode and read as the same instant in UTC', () {
      final expiresAt = DateTime.utc(2026, 10, 21, 12, 30, 15, 250);

      final stored = encodeAccessTokenExpiry(expiresAt);

      expect(stored, '${expiresAt.millisecondsSinceEpoch}');
      expect(readAccessTokenExpiry(stored), expiresAt);
      expect(readAccessTokenExpiry(stored)!.isUtc, isTrue);
    });

    test('a local time is stored as the same instant', () {
      final local = DateTime(2026, 10, 21, 12, 30);

      expect(encodeAccessTokenExpiry(local), '${local.toUtc().millisecondsSinceEpoch}');
      expect(readAccessTokenExpiry(encodeAccessTokenExpiry(local))!.isAtSameMomentAs(local), isTrue);
    });

    test('no stored expiry reads as null', () {
      expect(readAccessTokenExpiry(null), isNull);
    });

    test('a stored value that is not an integer throws FormatException', () {
      expect(() => readAccessTokenExpiry('2026-10-21T12:00:00Z'), throwsFormatException);
      expect(() => readAccessTokenExpiry(''), throwsFormatException);
    });
  });
}
