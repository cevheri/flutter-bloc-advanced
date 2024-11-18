import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/configuration/environment.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
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

  group("AccountRepository Register", () {
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

  group("Register", () {
    TestUtils.initWidgetDependencies();

    /// Register endpoint does not require AccessToken, this endpoint added to the allowed endpoints in the HttpUtils class
    test("Given valid user without token when register then return user successfully", () async {
      final newUser = mockUserFullPayload;
      final result = await AccountRepository().register(newUser);
      expect(result, isA<User>());
    });
  });
}
