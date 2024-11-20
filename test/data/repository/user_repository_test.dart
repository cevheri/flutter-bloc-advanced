import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
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

  //getUsers
  group("User Repository getUsers", () {
    test("Given valid user when getUsers then return user list successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().getUsers();
      expect(result, isA<List<User>>());
      expect(result.length, 4);
    });

    test("Given valid user without accessToken when getUsers then return user list fail", () async {
      expect(() async => await UserRepository().getUsers(), throwsA(isA<UnauthorizedException>()));
    });
  });

  //getUser
  group("User Repository getUser", () {
    test("Given valid userId when getUser then return user successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().getUser("user-1");
      expect(result, isA<User>());
      expect(result?.id, "user-1");
      expect(result?.login, "admin");
      expect(result?.firstName, "Admin");
      expect(result?.lastName, "User");
      expect(result?.email, "admin@sekoya.tech");
      expect(result?.activated, true);
      expect(result?.langKey, "en");
      expect(result?.createdBy, "system");
      expect(result?.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.lastModifiedBy, "admin");
      expect(result?.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid userId without accessToken when getUser then return user fail", () async {
      expect(() async => await UserRepository().getUser("1"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null userId when getUser then return user fail", () async {
      TestUtils().setupAuthentication();
      expect(() async => await UserRepository().getUser(""), throwsA(isA<BadRequestException>()));
    });
  });

  //getUserByLogin
  group("User Repository getUserByLogin", () {
    test("Given valid login when getUserByLogin then return user successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().getUserByLogin("username");
      expect(result, isA<User>());
      expect(result?.id, "user-1");
      expect(result?.login, "admin");
      expect(result?.firstName, "Admin");
      expect(result?.lastName, "User");
      expect(result?.email, "admin@sekoya.tech");
      expect(result?.activated, true);
      expect(result?.langKey, "en");
      expect(result?.createdBy, "system");
      expect(result?.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.lastModifiedBy, "admin");
      expect(result?.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid login without accessToken when getUserByLogin then return user fail", () async {
      expect(() async => await UserRepository().getUserByLogin("admin"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null login when getUserByLogin then return user fail", () async {
      TestUtils().setupAuthentication();
      expect(() async => await UserRepository().getUserByLogin(""), throwsA(isA<BadRequestException>()));
    });
  });

  //createUser
  group("User Repository createUser", () {
    test("Given valid user when createUser then return user successfully", () async {
      TestUtils().setupAuthentication();
      final user = mockUserFullPayload;
      final result = await UserRepository().createUser(user);
      expect(result, isA<User>());
      expect(result?.id, "user-1");
      expect(result?.login, "admin");
      expect(result?.firstName, "Admin");
      expect(result?.lastName, "User");
      expect(result?.email, "admin@sekoya.tech");
      expect(result?.activated, true);
      expect(result?.langKey, "en");
      expect(result?.createdBy, "system");
      expect(result?.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.lastModifiedBy, "admin");
      expect(result?.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid user without accessToken when createUser then return user fail", () async {
      expect(() async => await UserRepository().createUser(mockUserFullPayload), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null user when createUser then return user fail", () async {
      TestUtils().setupAuthentication();
      expect(() async => await UserRepository().createUser(User()), throwsA(isA<BadRequestException>()));
    });

    test("Given null username when createUser then return user fail", () async {
      TestUtils().setupAuthentication();
      expect(() async => await UserRepository().createUser(User(login: "admin")), throwsA(isA<BadRequestException>()));
    });
  });

  //listUser
  group("User Repository listUser", () {
    test("Given valid range when listUser then return user list successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().listUser(0, 10);
      expect(result, isA<List<User>>());
      expect(result.length, 4);
    });

    test("Given valid range without accessToken when listUser then return user list fail", () async {
      expect(() async => await UserRepository().listUser(0, 10), throwsA(isA<UnauthorizedException>()));
    });
  });

  //findUserByAuthority Future<List<User>> findUserByAuthority(int rangeStart, int rangeEnd, String authority) async {
  group("User Repository findUserByAuthority", () {
    test("Given valid range and authority when findUserByAuthority then return user list successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().findUserByAuthority(0, 10, "ROLE_ADMIN");
      expect(result, isA<List<User>>());
      expect(result.length, 4);
    });

    test("Given valid range and authority without accessToken when findUserByAuthority then return user list fail", () async {
      expect(() async => await UserRepository().findUserByAuthority(0, 10, "ROLE_ADMIN"), throwsA(isA<UnauthorizedException>()));
    });
  });

  //FindUserByName Future<List<User>> findUserByName(int rangeStart, int rangeEnd, String name, String authority) async {
  group("User Repository findUserByName", () {
    test("Given valid range, name and authority when findUserByName then return user list successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().findUserByName(0, 10, "admin", "ROLE_ADMIN");
      expect(result, isA<List<User>>());
      expect(result.length, 4);
    });

    test("Given valid range, name and authority without accessToken when findUserByName then return user list fail", () async {
      expect(() async => await UserRepository().findUserByName(0, 10, "admin", "ROLE_ADMIN"), throwsA(isA<UnauthorizedException>()));
    });
  });

  //updateUser
  group("User Repository updateUser", () {
    test("Given valid user when updateUser then return user successfully", () async {
      TestUtils().setupAuthentication();
      final user = mockUserFullPayload;
      final result = await UserRepository().updateUser(user);
      expect(result, isA<User>());
      expect(result?.id, "user-1");
      expect(result?.login, "admin");
      expect(result?.firstName, "Admin");
      expect(result?.lastName, "User");
      expect(result?.email, "admin@sekoya.tech");
      expect(result?.activated, true);
      expect(result?.langKey, "en");
      expect(result?.createdBy, "system");
      expect(result?.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.lastModifiedBy, "admin");
      expect(result?.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid user without accessToken when updateUser then return user fail", () async {
      expect(() async => await UserRepository().updateUser(mockUserFullPayload), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null user when updateUser then return user fail", () async {
      TestUtils().setupAuthentication();
      expect(() async => await UserRepository().updateUser(User()), throwsA(isA<BadRequestException>()));
    });
  });

  //deleteUser
  group("User Repository deleteUser", () {
    test("Given valid userId when deleteUser then return void successfully", () async {
      TestUtils().setupAuthentication();
      await UserRepository().deleteUser("user-1");
    });

    test("Given valid userId without accessToken when deleteUser then return void fail", () async {
      expect(() async => await UserRepository().deleteUser("1"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null userId when deleteUser then return void fail", () async {
      TestUtils().setupAuthentication();
      expect(() async => await UserRepository().deleteUser(""), throwsA(isA<BadRequestException>()));
    });
  });
}
