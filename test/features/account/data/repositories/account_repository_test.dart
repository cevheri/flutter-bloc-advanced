import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/fake_data.dart';
import '../../../../test_utils.dart';

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
      expect(result, isA<Success<UserEntity>>());
      final data = (result as Success<UserEntity>).data;
      expect(data.id, "user-2");
      expect(data.login, "user");
      expect(data.email, "user@sample.tech");
      expect(data.firstName, "User");
      expect(data.lastName, "User");
      expect(data.langKey, "en");
      expect(data.createdBy, "system");
      expect(data.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.lastModifiedBy, "admin");
      expect(data.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.authorities, ["ROLE_USER"]);
    });

    test("Given valid without langKey user when register then return user successfully", () async {
      var entity = mockUserFullPayload;
      entity = entity.copyWith(langKey: "");
      final result = await AccountRepository().register(entity);

      //check assets/mock/POST_register.json
      expect(result, isA<Success<UserEntity>>());
      final data = (result as Success<UserEntity>).data;
      expect(data.id, "user-2");
      expect(data.login, "user");
      expect(data.email, "user@sample.tech");
      expect(data.firstName, "User");
      expect(data.lastName, "User");
      expect(data.langKey, "en");
      expect(data.createdBy, "system");
      expect(data.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.lastModifiedBy, "admin");
      expect(data.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.authorities, ["ROLE_USER"]);
    });

    test("Given user with empty email when register then return Failure with ValidationError", () async {
      final entity = mockUserFullPayload.copyWith(email: "");
      final result = await AccountRepository().register(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });

    test("Given user with null login when register then return Success", () async {
      const entity = User(firstName: "test", lastName: "test", email: "test@test.com");
      final result = await AccountRepository().register(entity);
      expect(result, isA<Success<UserEntity>>());
    });

    /// Register endpoint does not require AccessToken, this endpoint added to the allowed endpoints in the HttpUtils class
    test("Given valid user without token when register then return user successfully", () async {
      final entity = mockUserFullPayload;
      final result = await AccountRepository().register(entity);
      expect(result, isA<Success<UserEntity>>());
    });
  });

  //test changePassword
  group("AccountRepository Change Password", () {
    test("Given valid passwordChangeDTO when changePassword then return Success", () async {
      await TestUtils().setupAuthentication();
      const passwordChangeDTO = mockPasswordChangePayload;
      final result = await AccountRepository().changePassword(passwordChangeDTO);
      expect(result, isA<Success<void>>());
    });

    test("Given empty value passwordChangeDTO when changePassword then return Failure", () async {
      const passwordChangeDTO = PasswordChangeDTO();
      final result = await AccountRepository().changePassword(passwordChangeDTO);
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });

    test("Given empty passwords passwordChangeDTO when changePassword then return Failure", () async {
      final passwordChangeDTO = mockPasswordChangePayload.copyWith(currentPassword: "", newPassword: "");
      final result = await AccountRepository().changePassword(passwordChangeDTO);
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });
  });

  //test resetPassword
  group("AccountRepository Reset Password", () {
    test("Given valid mailAddress when resetPassword then return Success", () async {
      await TestUtils().setupAuthentication();
      const mailAddress = "admin@sample.tech";
      final result = await AccountRepository().resetPassword(mailAddress);
      expect(result, isA<Success<void>>());
    });

    test("Given empty mailAddress when resetPassword then return Failure with ValidationError", () async {
      final result = await AccountRepository().resetPassword("");
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });

    test("Given invalid mailAddress when resetPassword then return Failure with ValidationError", () async {
      final result = await AccountRepository().resetPassword("test");
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });
  });

  //test getAccount
  group("AccountRepository Get Account", () {
    //success
    test("Given valid user when getAccount then return Success", () async {
      await TestUtils().setupAuthentication();
      final result = await AccountRepository().getAccount();
      expect(result, isA<Success<UserEntity>>());
    });

    //fail: without AccessToken
    test("Given getAccount without AccessToken then return Failure with AuthError", () async {
      final result = await AccountRepository().getAccount();
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<AuthError>());
    });
  });

  //test saveAccount
  group("AccountRepository Save Account", () {
    //success
    test("Given valid user when saveAccount then return Success", () async {
      await TestUtils().setupAuthentication();
      final entity = mockUserFullPayload;
      final result = await AccountRepository().update(entity);
      expect(result, isA<Success<UserEntity>>());
    });

    //fail: without AccessToken
    test("Given valid user when saveAccount without AccessToken then return Failure with AuthError", () async {
      final entity = mockUserFullPayload;
      final result = await AccountRepository().update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<AuthError>());
    });

    test("Given user with empty id when saveAccount then return Failure with ValidationError", () async {
      await TestUtils().setupAuthentication();
      const entity = User();
      final result = await AccountRepository().update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });

    test("Given user with blank id when saveAccount then return Failure with ValidationError", () async {
      await TestUtils().setupAuthentication();
      final entity = mockUserFullPayload.copyWith(id: "");
      final result = await AccountRepository().update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });
  });

  //test updateAccount
  group("AccountRepository Update Account", () {
    //success
    test("Given valid user when updateAccount then return Success", () async {
      await TestUtils().setupAuthentication();
      final entity = mockUserFullPayload;
      final result = await AccountRepository().update(entity);
      expect(result, isA<Success<UserEntity>>());
    });

    //fail: without AccessToken
    test("Given valid user when updateAccount without AccessToken then return Failure with AuthError", () async {
      final entity = mockUserFullPayload;
      final result = await AccountRepository().update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<AuthError>());
    });

    test("Given user with null id when updateAccount then return Failure with ValidationError", () async {
      await TestUtils().setupAuthentication();
      const entity = User();
      final result = await AccountRepository().update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });

    test("Given user with blank id when updateAccount then return Failure with ValidationError", () async {
      await TestUtils().setupAuthentication();
      final entity = mockUserFullPayload.copyWith(id: "");
      final result = await AccountRepository().update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });
  });

  //test deleteAccount
  group("AccountRepository Delete Account", () {
    //success
    test("Given valid id when deleteAccount then return Success", () async {
      await TestUtils().setupAuthentication();
      final result = await AccountRepository().delete("id");
      expect(result, isA<Success<void>>());
    });

    //fail: without AccessToken
    test("Given valid id when deleteAccount without AccessToken then return Failure with AuthError", () async {
      final result = await AccountRepository().delete("id");
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<AuthError>());
    });

    test("Given empty id when deleteAccount then return Failure with ValidationError", () async {
      await TestUtils().setupAuthentication();
      final result = await AccountRepository().delete("");
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });
  });
}
