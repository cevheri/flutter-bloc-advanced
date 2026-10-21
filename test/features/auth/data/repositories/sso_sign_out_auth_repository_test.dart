import 'dart:convert';

import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/sso_sign_out_auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

/// The secure store of the session in memory, which records each read in [calls] and throws on a read when
/// [readError] is set.
class _RecordingSecureStorage implements ISecureStorage {
  _RecordingSecureStorage(this.calls);

  final List<String> calls;
  final values = <String, String>{};
  Object? readError;

  @override
  Future<String?> read(String key) async {
    calls.add('read $key');
    final error = readError;
    if (error != null) throw error;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();
}

/// The local logout, which records itself in [calls], wipes [storage] and answers [logoutResult].
class _RecordingAuthRepository implements IAuthRepository {
  _RecordingAuthRepository(this.calls, this.storage);

  final List<String> calls;
  final _RecordingSecureStorage storage;
  Result<void> logoutResult = const Success(null);

  @override
  Future<Result<void>> logout() async {
    calls.add('wipe');
    await storage.deleteAll();
    return logoutResult;
  }

  @override
  Future<Result<AuthTokenEntity>> authenticate(AuthCredentialsEntity userJWT) =>
      throw UnimplementedError('a logout never authenticates');

  @override
  Future<Result<void>> sendOtp(SendOtpEntity request) => throw UnimplementedError('a logout never sends an OTP');

  @override
  Future<Result<AuthTokenEntity>> verifyOtp(VerifyOtpEntity request) =>
      throw UnimplementedError('a logout never verifies an OTP');
}

/// Ends the provider session with [outcome], recording the hint of each call in [calls].
class _FakeOidcClient implements IOidcClient {
  _FakeOidcClient(this.calls);

  final List<String> calls;
  OidcLogoutOutcome outcome = const ProviderSessionEnded();
  final hints = <String?>[];

  @override
  Future<OidcLogoutOutcome> endProviderSession({String? idTokenHint}) async {
    calls.add('endProviderSession');
    hints.add(idTokenHint);
    return outcome;
  }

  @override
  Future<OidcSignInOutcome> signIn({String? webReturnPath, required String browserDoneMessage}) =>
      throw UnimplementedError('a logout never signs in');

  @override
  Future<OidcSignInOutcome?> completePendingSignIn() => throw UnimplementedError('a logout completes no sign-in');

  @override
  Future<TokenRotationResult> refresh({
    required String refreshToken,
    required String idToken,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  }) => throw UnimplementedError('a logout never refreshes');
}

OidcSettings _settings({bool logoutHint = true}) =>
    OidcSettings(issuer: Uri.parse('https://id.example.com/realms/demo'), clientId: 'app', logoutHint: logoutHint);

/// An unsigned JWT whose payload carries [exp], in seconds since the epoch.
String _jwt({required int exp}) {
  String part(Map<String, Object> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part({'sub': 'subject-1', 'exp': exp})}.';
}

void main() {
  late List<String> calls;
  late _RecordingSecureStorage storage;
  late _RecordingAuthRepository inner;
  late _FakeOidcClient client;

  SsoSignOutAuthRepository repository({bool logoutHint = true}) => SsoSignOutAuthRepository(
    inner: inner,
    client: client,
    secureStorage: storage,
    settings: _settings(logoutHint: logoutHint),
  );

  setUp(() {
    calls = [];
    storage = _RecordingSecureStorage(calls);
    inner = _RecordingAuthRepository(calls, storage);
    client = _FakeOidcClient(calls);
    storage.values[SecureStorageKeys.oidcIdToken.key] = 'stored-id-token';
  });

  group('SsoSignOutAuthRepository.logout', () {
    test('reads the ID token before the wipe, then ends the provider session with it as the hint', () async {
      final result = await repository().logout();

      expect(result, const Success<void>(null));
      expect(calls, ['read ${SecureStorageKeys.oidcIdToken.key}', 'wipe', 'endProviderSession']);
      expect(client.hints, ['stored-id-token']);
    });

    test('sends no hint when OIDC_LOGOUT_HINT is off', () async {
      await repository(logoutHint: false).logout();

      expect(client.hints, [null]);
      expect(calls.last, 'endProviderSession');
    });

    // Keycloak gives the ID token the access token's short life, and accepts an expired one at end_session.
    test('sends an expired ID token as the hint, with no expiry check of its own', () async {
      final expired = _jwt(exp: DateTime.utc(2020).millisecondsSinceEpoch ~/ 1000);
      storage.values[SecureStorageKeys.oidcIdToken.key] = expired;

      await repository().logout();

      expect(client.hints, [expired]);
    });

    test('sends no hint when no ID token is stored', () async {
      storage.values.clear();

      await repository().logout();

      expect(client.hints, [null]);
    });

    test('sends no hint when the ID token cannot be read, and still wipes and ends the provider session', () async {
      storage.readError = Exception('keystore locked');

      final result = await repository().logout();

      expect(result, const Success<void>(null));
      expect(calls, ['read ${SecureStorageKeys.oidcIdToken.key}', 'wipe', 'endProviderSession']);
      expect(client.hints, [null]);
    });

    group('answers', () {
      const wipeFailure = Failure<void>(UnknownError('Session clear failed: jwtToken'));

      for (final (name, outcome) in <(String, OidcLogoutOutcome)>[
        ('the provider session ended', const ProviderSessionEnded()),
        ('the provider has no logout', const NoProviderLogout()),
        ('the web tab left for the provider logout', const ProviderLogoutNavigatedAway()),
      ]) {
        test('the local result when $name', () async {
          client.outcome = outcome;
          expect(await repository().logout(), const Success<void>(null));

          inner.logoutResult = wipeFailure;
          expect(await repository().logout(), wipeFailure);
        });
      }

      test('the incomplete provider logout when the provider logout failed after a clean wipe', () async {
        client.outcome = const ProviderLogoutFailed();

        final result = await repository().logout();

        expect(
          result,
          isA<Failure<void>>().having(
            (failure) => failure.error,
            'error',
            isA<AuthError>().having((error) => error.code, 'code', AppErrorCode.authOidcLogoutIncomplete.key),
          ),
        );
      });

      // The data left on this device is the more serious of the two, and the user can only be told one of them.
      test('the wipe failure when both the wipe and the provider logout failed', () async {
        client.outcome = const ProviderLogoutFailed();
        inner.logoutResult = wipeFailure;

        expect(await repository().logout(), wipeFailure);
      });
    });
  });

  group('SsoSignOutAuthRepository delegates the password sign-in to the repository it wraps', () {
    late MockIAuthRepository wrapped;
    late SsoSignOutAuthRepository delegating;

    setUp(() {
      wrapped = MockIAuthRepository();
      delegating = SsoSignOutAuthRepository(
        inner: wrapped,
        client: client,
        secureStorage: storage,
        settings: _settings(),
      );
    });

    test('authenticate', () async {
      const credentials = AuthCredentialsEntity(username: 'admin', password: 'password');
      const token = Success(AuthTokenEntity(idToken: 'token'));
      when(() => wrapped.authenticate(credentials)).thenAnswer((_) async => token);

      expect(await delegating.authenticate(credentials), token);
    });

    test('sendOtp', () async {
      const request = SendOtpEntity(email: 'user@example.com');
      when(() => wrapped.sendOtp(request)).thenAnswer((_) async => const Success(null));

      expect(await delegating.sendOtp(request), const Success<void>(null));
    });

    test('verifyOtp', () async {
      const request = VerifyOtpEntity(email: 'user@example.com', otp: '123456');
      const token = Success(AuthTokenEntity(idToken: 'token'));
      when(() => wrapped.verifyOtp(request)).thenAnswer((_) async => token);

      expect(await delegating.verifyOtp(request), token);
    });
  });
}
