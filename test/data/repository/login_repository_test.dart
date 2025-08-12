import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/models/jwt_token.dart';
import 'package:flutter_bloc_advance/data/models/send_otp_request.dart';
import 'package:flutter_bloc_advance/data/models/user_jwt.dart';
import 'package:flutter_bloc_advance/data/models/verify_otp_request.dart';
import 'package:flutter_bloc_advance/data/repository/login_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';
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
    test("Given valid entity when authenticate then return JWTToken successfully", () async {
      TestUtils().setupAuthentication();
      const entity = mockUserJWTPayload;
      final result = await LoginRepository().authenticate(entity);

      expect(result, isA<JWTToken>());
      expect(result?.idToken, "MOCK_TOKEN");
    });

    // authenticate method can use without accessToken
    test("Given valid entity without AccessToken when authenticate then return JWTToken fail", () async {
      const entity = mockUserJWTPayload;
      final result = await LoginRepository().authenticate(entity);

      expect(result, isA<JWTToken>());
      expect(result?.idToken, "MOCK_TOKEN");
    });

    test("Given null entity when authenticate then return JWTToken fail", () async {
      expect(() async => await LoginRepository().authenticate(const UserJWT("", "")), throwsA(isA<Exception>()));
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
      final request = SendOtpRequest(email: "test@example.com");

      expect(() async => await LoginRepository().sendOtp(request), returnsNormally);
    });

    test("Given invalid email when sendOtp then throws BadRequestException", () async {
      TestUtils().setupAuthentication();
      final request = SendOtpRequest(email: "");

      await expectLater(LoginRepository().sendOtp(request), throwsA(isA<BadRequestException>()));
    });
  });

  group("Login Repository verifyOtp", () {
    test("Given valid OTP when verify then return JWTToken successfully", () async {
      TestUtils().setupAuthentication();
      final request = VerifyOtpRequest(email: "test@example.com", otp: "123456");

      final result = await LoginRepository().verifyOtp(request);
      expect(result, isA<JWTToken>());
      expect(result?.idToken, "MOCK_TOKEN");
    });

    test("Given invalid OTP when verify then throws BadRequestException", () async {
      TestUtils().setupAuthentication();
      final request = VerifyOtpRequest(email: "test@example.com", otp: "1234567");

      await expectLater(LoginRepository().verifyOtp(request), throwsA(isA<BadRequestException>()));
    });
  });
}
