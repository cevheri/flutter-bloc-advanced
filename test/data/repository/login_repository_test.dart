import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/models/jwt_token.dart';
import 'package:flutter_bloc_advance/data/models/user_jwt.dart';
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
    test("Given valid userJWT when authenticate then return JWTToken successfully", () async {
      TestUtils().setupAuthentication();
      final userJWT = mockUserJWTPayload;
      final result = await LoginRepository().authenticate(userJWT);

      expect(result, isA<JWTToken>());
      expect(result?.idToken, "MOCK_TOKEN");
    });

    // authenticate method can use without accessToken
    test("Given valid userJWT without AccessToken when authenticate then return JWTToken fail", () async {
      final userJWT = mockUserJWTPayload;
      final result = await LoginRepository().authenticate(userJWT);

      expect(result, isA<JWTToken>());
      expect(result?.idToken, "MOCK_TOKEN");
    });

    test("Given null userJWT when authenticate then return JWTToken fail", () async {
      expect(() async => await LoginRepository().authenticate(UserJWT("", "")), throwsA(isA<Exception>()));
    });

    test("Given stored userJWT when logout then clear storage successfully", () async {
      TestUtils().setupAuthentication();
      expect(await AppLocalStorage().read(StorageKeys.jwtToken.name), isNotNull);
      expect(await AppLocalStorage().read(StorageKeys.jwtToken.name), isA<String>());
      await LoginRepository().logout();
      expect(await AppLocalStorage().read(StorageKeys.jwtToken.name), null);
    });
  });
}
