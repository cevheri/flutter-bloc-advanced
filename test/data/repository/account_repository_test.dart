import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/utils/storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';
import '../../test_utils.dart';

void main() {
  AccountRepository accountRepository = AccountRepository();

  group("AccountRepository Register", () {
    TestUtils.initTestDependenciesWithToken();

    test("Given valid user when register then return user successfully", () async {
      final newUser = mockUserFullPayload;
      final result = await accountRepository.register(newUser);

      //check assets/mock/POST_register.json
      expect(result, isA<User>());
      expect(result?.id, "user-2");
      expect(result?.login, "user");
      expect(result?.email, "user@sekoya.tech");
      expect(result?.firstName, "User");
      expect(result?.lastName, "User");
      expect(result?.langKey, "en");
      expect(result?.createdBy, "system");
      expect(result?.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.lastModifiedBy, "admin");
      expect(result?.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.authorities, ["ROLE_USER"]);
    });

    test("Given null user when register then throw BadRequestException", () async {
      expect(() => accountRepository.register(null), throwsA(isA<BadRequestException>()));
    });

    test("Given user with null email when register then throw BadRequestException", () async {
      final newUser = mockUserFullPayload.copyWith(email: "");

      expect(() => accountRepository.register(newUser), throwsA(isA<BadRequestException>()));
    });

    test("Given user with null login when register then throw BadRequestException", () async {
      final newUser = mockUserFullPayload.copyWith(login: "");
      expect(() => accountRepository.register(newUser), throwsA(isA<BadRequestException>()));
    });
  });

  group("Register", () {
    TestUtils.initTestDependenciesWithToken();

    /// Register endpoint does not require AccessToken, this endpoint added to the allowed endpoints in the HttpUtils class
    test("Given valid user without token when register then return user successfully", () async {
      final newUser = mockUserFullPayload;
      final result = await accountRepository.register(newUser);
      expect(result, isA<User>());
    });
  });
}
