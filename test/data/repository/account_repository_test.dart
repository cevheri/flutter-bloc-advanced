import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/models/change_password.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';
import '../../test_utils.dart';

void main() {
  //region setup
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });
  //endregion setup

  //test register
  group("AccountRepository Register success", () {
    test("Given valid user when register then return user successfully", () async {
      final entity = mockUserFullPayload;
      final result = await AccountRepository().register(entity);

      //check assets/mock/POST_register.json
      expect(result, isA<User>());
      expect(result?.id, "user-2");
      expect(result?.login, "user");
      expect(result?.email, "user@sample.tech");
      expect(result?.firstName, "User");
      expect(result?.lastName, "User");
      expect(result?.langKey, "en");
      expect(result?.createdBy, "system");
      expect(result?.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.lastModifiedBy, "admin");
      expect(result?.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.authorities, ["ROLE_USER"]);
    });

    test("Given valid without langKey user when register then return user successfully", () async {
      var entity = mockUserFullPayload;
      entity = entity.copyWith(langKey: "");
      final result = await AccountRepository().register(entity);

      //check assets/mock/POST_register.json
      expect(result, isA<User>());
      expect(result?.id, "user-2");
      expect(result?.login, "user");
      expect(result?.email, "user@sample.tech");
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
      expect(() => AccountRepository().register(null), throwsA(isA<BadRequestException>()));
    });

    test("Given user with null email when register then throw BadRequestException", () async {
      final entity = mockUserFullPayload.copyWith(email: "");

      expect(() => AccountRepository().register(entity), throwsA(isA<BadRequestException>()));
    });

    test("Given user with null login when register then throw BadRequestException", () async {
      const entity = User(firstName: "test", lastName: "test", email: "test@test.com");
      await AccountRepository().register(entity);
    });

    /// Register endpoint does not require AccessToken, this endpoint added to the allowed endpoints in the HttpUtils class
    test("Given valid user without token when register then return user successfully", () async {
      final entity = mockUserFullPayload;
      final result = await AccountRepository().register(entity);
      expect(result, isA<User>());
    });
  });

  //test changePassword
  group("AccountRepository Change Password", () {
    test("Given valid passwordChangeDTO when changePassword then return 200", () async {
      await TestUtils().setupAuthentication();
      const passwordChangeDTO = mockPasswordChangePayload;
      final result = await AccountRepository().changePassword(passwordChangeDTO);
      expect(result, lessThan(300));
    });

    test("Given null passwordChangeDTO when changePassword then throw BadRequestException", () async {
      expect(() => AccountRepository().changePassword(null), throwsA(isA<BadRequestException>()));
    });
    test("Given empty value passwordChangeDTO when changePassword then throw BadRequestException", () async {
      const passwordChangeDTO = PasswordChangeDTO();
      expect(() => AccountRepository().changePassword(passwordChangeDTO), throwsA(isA<BadRequestException>()));
    });
    test("Given null value passwordChangeDTO when changePassword then throw BadRequestException", () async {
      final passwordChangeDTO = mockPasswordChangePayload.copyWith(currentPassword: "", newPassword: "");
      expect(() => AccountRepository().changePassword(passwordChangeDTO), throwsA(isA<BadRequestException>()));
    });
  });

  //test resetPassword
  group("AccountRepository Reset Password", () {
    test("Given valid mailAddress when resetPassword then return 200", () async {
      await TestUtils().setupAuthentication();
      const mailAddress = "admin@sample.tech";
      final result = await AccountRepository().resetPassword(mailAddress);
      expect(result, lessThan(300));
    });

    test("Given null mailAddress when resetPassword then throw BadRequestException", () async {
      expect(() => AccountRepository().resetPassword(""), throwsA(isA<BadRequestException>()));
    });
    test("Given invalid mailAddress when resetPassword then throw BadRequestException", () async {
      expect(() => AccountRepository().resetPassword("test"), throwsA(isA<BadRequestException>()));
    });
  });

  //test getAccount
  group("AccountRepository Get Account", () {
    //success
    test("Given valid user when getAccount then return user successfully", () async {
      await TestUtils().setupAuthentication();
      final result = await AccountRepository().getAccount();
      expect(result, isA<User>());
    });
    //fail: without AccessToken
    test("Given valid user when getAccount without AccessToken then return user successfully", () async {
      expect(() => AccountRepository().getAccount(), throwsA(isA<UnauthorizedException>()));
    });

    //fail
    test("Given getAccount when without AccessToken then throw BadRequestException", () async {
      expect(() => AccountRepository().getAccount(), throwsA(isA<UnauthorizedException>()));
    });
  });

  //test saveAccount
  group("AccountRepository Save Account", () {
    //success
    test("Given valid user when saveAccount then return user successfully", () async {
      await TestUtils().setupAuthentication();
      final entity = mockUserFullPayload;
      final result = await AccountRepository().update(entity);
      expect(result, isA<User>());
    });
    //fail: without AccessToken
    test("Given valid user when saveAccount without AccessToken then return user successfully", () async {
      final entity = mockUserFullPayload;
      expect(() => AccountRepository().update(entity), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null user when saveAccount then throw BadRequestException", () async {
      await TestUtils().setupAuthentication();
      expect(() => AccountRepository().update(null), throwsA(isA<BadRequestException>()));
    });
    test("Given user with null id when saveAccount then throw BadRequestException", () async {
      await TestUtils().setupAuthentication();
      const entity = User();
      expect(() => AccountRepository().update(entity), throwsA(isA<BadRequestException>()));
    });

    test("Given user with null id when saveAccount then throw BadRequestException", () async {
      await TestUtils().setupAuthentication();
      final entity = mockUserFullPayload.copyWith(id: "");
      expect(() => AccountRepository().update(entity), throwsA(isA<BadRequestException>()));
    });
  });

  //test updateAccount
  group("AccountRepository Update Account", () {
    //success
    test("Given valid user when updateAccount then return user successfully", () async {
      await TestUtils().setupAuthentication();
      final entity = mockUserFullPayload;
      final result = await AccountRepository().update(entity);
      expect(result, isA<User>());
    });
    //fail: without AccessToken
    test("Given valid user when updateAccount without AccessToken then return user successfully", () async {
      final entity = mockUserFullPayload;
      expect(() async => await AccountRepository().update(entity), throwsA(isA<UnauthorizedException>()));
    });

    test("Given user with null id when updateAccount then throw BadRequestException", () async {
      await TestUtils().setupAuthentication();
      const entity = User();
      expect(() async => await AccountRepository().update(entity), throwsA(isA<BadRequestException>()));
    });

    test("Given user with null id when updateAccount then throw BadRequestException", () async {
      await TestUtils().setupAuthentication();
      final entity = mockUserFullPayload.copyWith(id: "");
      expect(() async => await AccountRepository().update(entity), throwsA(isA<BadRequestException>()));
    });
  });

  //test deleteAccount
  group("AccountRepository Delete Account", () {
    //success
    test("Given valid id when deleteAccount then return void", () async {
      await TestUtils().setupAuthentication();
      final result = await AccountRepository().delete("id");
      expect(result, isTrue);
    });
    //fail: without AccessToken
    test("Given valid id when deleteAccount without AccessToken then return void", () async {
      expect(() async => await AccountRepository().delete("id"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null id when deleteAccount then throw BadRequestException", () async {
      await TestUtils().setupAuthentication();
      expect(() async => await AccountRepository().delete(""), throwsA(isA<BadRequestException>()));
    });
  });
}
