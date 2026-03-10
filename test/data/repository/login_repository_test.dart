import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  group("Login Repository authenticate", () {
    // authenticate method can use with accessToken
    test("Given valid entity when authenticate then return AuthTokenEntity successfully", () async {
      TestUtils().setupAuthentication();
      const entity = AuthCredentialsEntity(username: 'username', password: 'password');
      final result = await LoginRepository().authenticate(entity);

      expect(result, isA<AuthTokenEntity>());
      expect(result?.idToken, "MOCK_TOKEN");
    });

    // authenticate method can use without accessToken
    test("Given valid entity without AccessToken when authenticate then return AuthTokenEntity", () async {
      const entity = AuthCredentialsEntity(username: 'username', password: 'password');
      final result = await LoginRepository().authenticate(entity);

      expect(result, isA<AuthTokenEntity>());
      expect(result?.idToken, "MOCK_TOKEN");
    });

    test("Given empty entity when authenticate then throw exception", () async {
      expect(
        () async => await LoginRepository().authenticate(const AuthCredentialsEntity(username: "", password: "")),
        throwsA(isA<Exception>()),
      );
    });

    test("Given stored entity when logout then clear storage successfully", () async {
      TestUtils().setupAuthentication();

      expect(await AppLocalStorage().read(StorageKeys.jwtToken.name), isNotNull);
      expect(await AppLocalStorage().read(StorageKeys.jwtToken.name), isA<String>());

      expect(() async => await LoginRepository().logout(), returnsNormally);
      expect(await AppLocalStorage().read(StorageKeys.jwtToken.name), null);
    });
  });

  group("Login Repository sendOtp", () {
    test("Given valid email when sendOtp then complete successfully", () async {
      TestUtils().setupAuthentication();
      const request = SendOtpEntity(email: "test@example.com");

      expect(() async => await LoginRepository().sendOtp(request), returnsNormally);
    });

    test("Given invalid email when sendOtp then throws BadRequestException", () async {
      TestUtils().setupAuthentication();
      const request = SendOtpEntity(email: "");

      await expectLater(LoginRepository().sendOtp(request), throwsA(isA<BadRequestException>()));
    });
  });

  group("Login Repository verifyOtp", () {
    test("Given valid OTP when verify then return AuthTokenEntity successfully", () async {
      TestUtils().setupAuthentication();
      const request = VerifyOtpEntity(email: "test@example.com", otp: "123456");

      final result = await LoginRepository().verifyOtp(request);
      expect(result, isA<AuthTokenEntity>());
      expect(result?.idToken, "MOCK_TOKEN");
    });

    test("Given invalid OTP when verify then throws BadRequestException", () async {
      TestUtils().setupAuthentication();
      const request = VerifyOtpEntity(email: "test@example.com", otp: "1234567");

      await expectLater(LoginRepository().verifyOtp(request), throwsA(isA<BadRequestException>()));
    });
  });
}
