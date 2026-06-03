import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_env.dart';

/// ISecureStorage that throws on the configured delete key. Used to
/// exercise the best-effort sequential cleanup path in logout.
class _FlakyDeleteSecureStorage implements ISecureStorage {
  _FlakyDeleteSecureStorage({required this.failOn});
  final String failOn;
  final Map<String, String> _store = {};
  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<void> write(String key, String value) async => _store[key] = value;
  @override
  Future<void> delete(String key) async {
    if (key == failOn) throw StateError('boom on $key');
    _store.remove(key);
  }

  @override
  Future<void> deleteAll() async => _store.clear();
}

void main() {
  group("Login Repository authenticate", () {
    // authenticate method can use with accessToken
    test("Given valid entity when authenticate then return Success with AuthTokenEntity", () async {
      TestEnv.authenticate();
      const entity = AuthCredentialsEntity(username: 'username', password: 'password');
      final result = await LoginRepository(apiClient: TestEnv.apiClient()).authenticate(entity);

      expect(result, isA<Success<AuthTokenEntity>>());
      expect(result.dataOrNull?.idToken, "MOCK_TOKEN");
    });

    // authenticate method can use without accessToken
    test("Given valid entity without AccessToken when authenticate then return Success with AuthTokenEntity", () async {
      const entity = AuthCredentialsEntity(username: 'username', password: 'password');
      final result = await LoginRepository(apiClient: TestEnv.apiClient()).authenticate(entity);

      expect(result, isA<Success<AuthTokenEntity>>());
      expect(result.dataOrNull?.idToken, "MOCK_TOKEN");
    });

    test("Given empty entity when authenticate then return Failure", () async {
      final result = await LoginRepository(
        apiClient: TestEnv.apiClient(),
      ).authenticate(const AuthCredentialsEntity(username: "", password: ""));
      expect(result, isA<Failure<AuthTokenEntity>>());
    });

    test("Given stored entity when logout then clear storage successfully", () async {
      final secure = FlutterSecureStorageAdapter();
      await secure.write(SecureStorageKeys.jwtToken.key, 'MOCK_TOKEN');
      expect(await secure.read(SecureStorageKeys.jwtToken.key), 'MOCK_TOKEN');

      final result = await LoginRepository(apiClient: TestEnv.apiClient()).logout();
      expect(result, isA<Success<void>>());
      // Both backends are wiped after logout — secure store no longer
      // holds the JWT, so AuthInterceptor cannot re-attach it.
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull);
    });

    test("logout keeps wiping even if one secure delete throws", () async {
      // ISecureStorage that throws on jwtToken delete but succeeds on
      // refreshToken delete — proves best-effort sequential cleanup:
      // a partial failure must not skip subsequent cleanup steps,
      // because any leftover token would let AuthInterceptor re-attach
      // it on the next request.
      final secure = _FlakyDeleteSecureStorage(failOn: SecureStorageKeys.jwtToken.key);
      await secure.write(SecureStorageKeys.refreshToken.key, 'REFRESH');

      final result = await LoginRepository(secureStorage: secure, apiClient: TestEnv.apiClient()).logout();

      expect(result, isA<Failure<void>>(), reason: 'partial failure surfaced as Failure');
      expect(
        await secure.read(SecureStorageKeys.refreshToken.key),
        isNull,
        reason: 'refresh delete ran even though jwt delete threw',
      );
    });

    test("logout wipes JWT and refresh token from secure storage", () async {
      // Seed both backends to simulate a fully-logged-in session.
      final secure = FlutterSecureStorageAdapter();
      await secure.write(SecureStorageKeys.jwtToken.key, 'JWT_VALUE');
      await secure.write(SecureStorageKeys.refreshToken.key, 'REFRESH_VALUE');
      expect(await secure.read(SecureStorageKeys.jwtToken.key), 'JWT_VALUE');

      final result = await LoginRepository(apiClient: TestEnv.apiClient()).logout();

      expect(result, isA<Success<void>>());
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull, reason: 'secure JWT must not survive logout');
      expect(
        await secure.read(SecureStorageKeys.refreshToken.key),
        isNull,
        reason: 'secure refresh must not survive logout',
      );
    });
  });

  group("Login Repository sendOtp", () {
    test("Given valid email when sendOtp then return Success", () async {
      TestEnv.authenticate();
      const request = SendOtpEntity(email: "test@example.com");

      final result = await LoginRepository(apiClient: TestEnv.apiClient()).sendOtp(request);
      expect(result, isA<Success<void>>());
    });

    test("Given invalid email when sendOtp then return Failure", () async {
      TestEnv.authenticate();
      const request = SendOtpEntity(email: "");

      final result = await LoginRepository(apiClient: TestEnv.apiClient()).sendOtp(request);
      expect(result, isA<Failure<void>>());
    });
  });

  group("Login Repository verifyOtp", () {
    test("Given valid OTP when verify then return Success with AuthTokenEntity", () async {
      TestEnv.authenticate();
      const request = VerifyOtpEntity(email: "test@example.com", otp: "123456");

      final result = await LoginRepository(apiClient: TestEnv.apiClient()).verifyOtp(request);
      expect(result, isA<Success<AuthTokenEntity>>());
      expect(result.dataOrNull?.idToken, "MOCK_TOKEN");
    });

    test("Given invalid OTP when verify then return Failure", () async {
      TestEnv.authenticate();
      const request = VerifyOtpEntity(email: "test@example.com", otp: "1234567");

      final result = await LoginRepository(apiClient: TestEnv.apiClient()).verifyOtp(request);
      expect(result, isA<Failure<AuthTokenEntity>>());
    });
  });
}
