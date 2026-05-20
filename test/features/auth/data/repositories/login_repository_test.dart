import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_utils.dart';

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  group("Login Repository authenticate", () {
    // authenticate method can use with accessToken
    test("Given valid entity when authenticate then return Success with AuthTokenEntity", () async {
      TestUtils().setupAuthentication();
      const entity = AuthCredentialsEntity(username: 'username', password: 'password');
      final result = await LoginRepository().authenticate(entity);

      expect(result, isA<Success<AuthTokenEntity>>());
      expect(result.dataOrNull?.idToken, "MOCK_TOKEN");
    });

    // authenticate method can use without accessToken
    test("Given valid entity without AccessToken when authenticate then return Success with AuthTokenEntity", () async {
      const entity = AuthCredentialsEntity(username: 'username', password: 'password');
      final result = await LoginRepository().authenticate(entity);

      expect(result, isA<Success<AuthTokenEntity>>());
      expect(result.dataOrNull?.idToken, "MOCK_TOKEN");
    });

    test("Given empty entity when authenticate then return Failure", () async {
      final result = await LoginRepository().authenticate(const AuthCredentialsEntity(username: "", password: ""));
      expect(result, isA<Failure<AuthTokenEntity>>());
    });

    test("Given stored entity when logout then clear storage successfully", () async {
      final secure = FlutterSecureStorageAdapter();
      await secure.write(SecureStorageKeys.jwtToken.key, 'MOCK_TOKEN');
      expect(await secure.read(SecureStorageKeys.jwtToken.key), 'MOCK_TOKEN');

      final result = await LoginRepository().logout();
      expect(result, isA<Success<void>>());
      // Both backends are wiped after logout — secure store no longer
      // holds the JWT, so AuthInterceptor cannot re-attach it.
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull);
    });

    test("logout wipes JWT and refresh token from secure storage", () async {
      // Seed both backends to simulate a fully-logged-in session.
      final secure = FlutterSecureStorageAdapter();
      await secure.write(SecureStorageKeys.jwtToken.key, 'JWT_VALUE');
      await secure.write(SecureStorageKeys.refreshToken.key, 'REFRESH_VALUE');
      expect(await secure.read(SecureStorageKeys.jwtToken.key), 'JWT_VALUE');

      final result = await LoginRepository().logout();

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
      TestUtils().setupAuthentication();
      const request = SendOtpEntity(email: "test@example.com");

      final result = await LoginRepository().sendOtp(request);
      expect(result, isA<Success<void>>());
    });

    test("Given invalid email when sendOtp then return Failure", () async {
      TestUtils().setupAuthentication();
      const request = SendOtpEntity(email: "");

      final result = await LoginRepository().sendOtp(request);
      expect(result, isA<Failure<void>>());
    });
  });

  group("Login Repository verifyOtp", () {
    test("Given valid OTP when verify then return Success with AuthTokenEntity", () async {
      TestUtils().setupAuthentication();
      const request = VerifyOtpEntity(email: "test@example.com", otp: "123456");

      final result = await LoginRepository().verifyOtp(request);
      expect(result, isA<Success<AuthTokenEntity>>());
      expect(result.dataOrNull?.idToken, "MOCK_TOKEN");
    });

    test("Given invalid OTP when verify then return Failure", () async {
      TestUtils().setupAuthentication();
      const request = VerifyOtpEntity(email: "test@example.com", otp: "1234567");

      final result = await LoginRepository().verifyOtp(request);
      expect(result, isA<Failure<AuthTokenEntity>>());
    });
  });
}
