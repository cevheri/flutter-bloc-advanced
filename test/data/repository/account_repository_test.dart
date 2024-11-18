import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/configuration/environment.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/models/change_password.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_bloc_advance/utils/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fake/user_data.dart';
import '../../test_utils.dart';

void main() {
  ProfileConstants.setEnvironment(Environment.TEST);
  initializeJsonMapper();
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall methodCall) async {
    return '.';
  });
  GetStorage.init("${Directory.systemTemp.createTempSync().path}/${Random().nextInt(1000)}");
  TestWidgetsFlutterBinding.ensureInitialized();

  //test register success
  group("AccountRepository Register success", () {
    TestUtils.initWidgetDependenciesWithToken();

    test("Given valid user when register then return user successfully", () async {
      final newUser = mockUserFullPayload;
      final result = await AccountRepository().register(newUser);

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
  });

  //test register with error
  group("AccountRepository Register with error ", () {
    TestUtils.initWidgetDependenciesWithToken();
    test("Given null user when register then throw BadRequestException", () async {
      expect(() => AccountRepository().register(null), throwsA(isA<BadRequestException>()));
    });

    test("Given user with null email when register then throw BadRequestException", () async {
      final newUser = mockUserFullPayload.copyWith(email: "");

      expect(() => AccountRepository().register(newUser), throwsA(isA<BadRequestException>()));
    });

    test("Given user with null login when register then throw BadRequestException", () async {
      final newUser = mockUserFullPayload.copyWith(login: "");
      expect(() => AccountRepository().register(newUser), throwsA(isA<BadRequestException>()));
    });
  });

  group("AccountRepository Register success without TOKEN", () {
    TestUtils.initWidgetDependencies();

    /// Register endpoint does not require AccessToken, this endpoint added to the allowed endpoints in the HttpUtils class
    test("Given valid user without token when register then return user successfully", () async {
      final newUser = mockUserFullPayload;
      final result = await AccountRepository().register(newUser);
      expect(result, isA<User>());
    });
  });

  //test change password success
  group("AccountRepository Change Password success", () {
    TestUtils.initWidgetDependenciesWithToken();

    test("Given valid passwordChangeDTO when changePassword then return 200", () async {
      final passwordChangeDTO = mockPasswordChangePayload;
      final result = await AccountRepository().changePassword(passwordChangeDTO);
      expect(result, 200);
    });
  });
  //test change password with error
  // group("AccountRepository Change Password with error", () {
  //   test("Given null passwordChangeDTO when changePassword then throw BadRequestException", () async {
  //     expect(() => AccountRepository().changePassword(null), throwsA(isA<BadRequestException>()));
  //   });
  //   test("Given empty value passwordChangeDTO when changePassword then throw BadRequestException", () async {
  //     final passwordChangeDTO = PasswordChangeDTO();
  //     expect(() => AccountRepository().changePassword(passwordChangeDTO), throwsA(isA<BadRequestException>()));
  //   });
  //   test("Given null value passwordChangeDTO when changePassword then throw BadRequestException", () async {
  //     final passwordChangeDTO = mockPasswordChangePayload.copyWith(currentPassword: "", newPassword: "");
  //     expect(() => AccountRepository().changePassword(passwordChangeDTO), throwsA(isA<BadRequestException>()));
  //   });
  // });

  //test reset password success
  group("AccountRepository Reset Password success", () {
    TestUtils.initWidgetDependenciesWithToken();

    test("Given valid mailAddress when resetPassword then return 200", () async {
      final mailAddress = "admin@sekoya.tech";
      final result = await AccountRepository().resetPassword(mailAddress);
      expect(result, 200);
    });
  });

  // //test reset password with error
  // group("AccountRepository Reset Password with error", () {
  //   test("Given null mailAddress when resetPassword then throw BadRequestException", () async {
  //     expect(() => AccountRepository().resetPassword(""), throwsA(isA<BadRequestException>()));
  //   });
  //   test("Given invalid mailAddress when resetPassword then throw BadRequestException", () async {
  //     expect(() => AccountRepository().resetPassword("test"), throwsA(isA<BadRequestException>()));
  //   });
  // });

  //test get account success
  group("AccountRepository Get Account success", () {
    TestUtils.initWidgetDependenciesWithToken();

    test("Given valid user when getAccount then return user successfully", () async {
      final result = await AccountRepository().getAccount();
      expect(result, isA<User>());
    });
  });
  // //test get account with error
  // group("AccountRepository Get Account with error", () {
  //   test("Given null user when getAccount then throw BadRequestException", () async {
  //     TestUtils.initWidgetDependencies();
  //     getStorageCache = {};
  //     expect(() => AccountRepository().getAccount(), throwsA(anything));
  //   });
  // });


  //test save account success
  group("AccountRepository Save Account success", () {
    TestUtils.initWidgetDependenciesWithToken();

    test("Given valid user when saveAccount then return user successfully", () async {
      final newUser = mockUserFullPayload;
      final result = await AccountRepository().saveAccount(newUser);
      expect(result, isA<User>());
    });
  });
  // //test save account with error
  // group("AccountRepository Save Account with error", () {
  //   test("Given null user when saveAccount then throw BadRequestException", () async {
  //     TestUtils.initWidgetDependencies();
  //     getStorageCache = {};
  //     expect(() => AccountRepository().saveAccount(null), throwsA(isA<BadRequestException>()));
  //   });
  //   test("Given user with null id when saveAccount then throw BadRequestException", () async {
  //     TestUtils.initWidgetDependencies();
  //     getStorageCache = {};
  //     final newUser = User();
  //     expect(() => AccountRepository().saveAccount(newUser), throwsA(isA<BadRequestException>()));
  //   });


    // test("Given user with null id when saveAccount then throw BadRequestException", () async {
    //   TestUtils.initWidgetDependencies();
    //   getStorageCache = {};
    //   final newUser = mockUserFullPayload.copyWith(id: "");
    //   expect(() => AccountRepository().saveAccount(newUser), throwsA(isA<BadRequestException>()));
    // });
  // });


  //test update account success
  //test update account with error

  //test delete account success
  //test delete account with error
}
