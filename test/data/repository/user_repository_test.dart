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

  group("User Repository getUsers", () {
    test("Given valid user when getUsers then return user list successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().list();
      expect(result, isA<List<User>>());
      expect(result.length, 4);
    });

    test("Given valid user without accessToken when getUsers then return user list fail", () async {
      expect(() async => await UserRepository().list(), throwsA(isA<UnauthorizedException>()));
    });
  });

  group("User Repository getUser", () {
    test("Given valid userId when getUser then return user successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().retrieve("user-1");

      expect(result, isA<User>());
      expect(result?.id, "user-1");
      expect(result?.login, "admin");
      expect(result?.firstName, "Admin");
      expect(result?.lastName, "User");
      expect(result?.email, "admin@sample.tech");
      expect(result?.activated, true);
      expect(result?.langKey, "en");
      expect(result?.createdBy, "system");
      expect(result?.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.lastModifiedBy, "admin");
      expect(result?.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid userId without accessToken when getUser then return user fail", () async {
      expect(() async => await UserRepository().retrieve("1"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null userId when getUser then return user fail", () async {
      TestUtils().setupAuthentication();

      expect(() async => await UserRepository().retrieve(""), throwsA(isA<BadRequestException>()));
    });
  });

  group("User Repository getUserByLogin", () {
    test("Given valid login when getUserByLogin then return user successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().retrieveByLogin("username");

      expect(result, isA<User>());
      expect(result?.id, "user-1");
      expect(result?.login, "admin");
      expect(result?.firstName, "Admin");
      expect(result?.lastName, "User");
      expect(result?.email, "admin@sample.tech");
      expect(result?.activated, true);
      expect(result?.langKey, "en");
      expect(result?.createdBy, "system");
      expect(result?.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.lastModifiedBy, "admin");
      expect(result?.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid login without accessToken when getUserByLogin then return user fail", () async {
      expect(() async => await UserRepository().retrieveByLogin("admin"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null login when getUserByLogin then return user fail", () async {
      TestUtils().setupAuthentication();

      expect(() async => await UserRepository().retrieveByLogin(""), throwsA(isA<BadRequestException>()));
    });
  });

  group("User Repository createUser", () {
    test("Given valid user when createUser then return user successfully", () async {
      TestUtils().setupAuthentication();
      final entity = mockUserFullPayload;
      final result = await UserRepository().create(entity);

      expect(result, isA<User>());
      expect(result?.id, "user-1");
      expect(result?.login, "admin");
      expect(result?.firstName, "Admin");
      expect(result?.lastName, "User");
      expect(result?.email, "admin@sample.tech");
      expect(result?.activated, true);
      expect(result?.langKey, "en");
      expect(result?.createdBy, "system");
      expect(result?.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.lastModifiedBy, "admin");
      expect(result?.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid user without accessToken when createUser then return user fail", () async {
      expect(() async => await UserRepository().create(mockUserFullPayload), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null user when createUser then return user fail", () async {
      TestUtils().setupAuthentication();

      expect(() async => await UserRepository().create(const User()), throwsA(isA<BadRequestException>()));
    });

    test("Given null username when createUser then return user fail", () async {
      TestUtils().setupAuthentication();

      expect(
        () async => await UserRepository().create(const User(login: "admin")),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group("User Repository listUser", () {
    test("Given valid range when listUser then return user list successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().list(page: 0, size: 10);

      expect(result, isA<List<User>>());
      expect(result.length, 4);
    });

    test("Given valid range without accessToken when listUser then return user list fail", () async {
      expect(() async => await UserRepository().list(page: 0, size: 10), throwsA(isA<UnauthorizedException>()));
    });
  });

  group("User Repository findUserByAuthority", () {
    test("Given valid range and authority when findUserByAuthority then return user list successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().listByAuthority(0, 10, "ROLE_ADMIN");

      expect(result, isA<List<User>>());
      expect(result.length, 4);
    });

    test(
      "Given valid range and authority without accessToken when findUserByAuthority then return user list fail",
      () async {
        expect(
          () async => await UserRepository().listByAuthority(0, 10, "ROLE_ADMIN"),
          throwsA(isA<UnauthorizedException>()),
        );
      },
    );
  });

  group("User Repository findUserByName", () {
    test("Given valid range, name and authority when findUserByName then return user list successfully", () async {
      TestUtils().setupAuthentication();
      final result = await UserRepository().listByNameAndRole(0, 10, "admin", "ROLE_ADMIN");

      expect(result, isA<List<User>>());
      expect(result.length, 4);
    });

    test(
      "Given valid range, name and authority without accessToken when findUserByName then return user list fail",
      () async {
        expect(
          () async => await UserRepository().listByNameAndRole(0, 10, "admin", "ROLE_ADMIN"),
          throwsA(isA<UnauthorizedException>()),
        );
      },
    );
  });

  group("User Repository updateUser", () {
    test("Given valid user when updateUser then return user successfully", () async {
      TestUtils().setupAuthentication();
      final entity = mockUserFullPayload;
      final result = await UserRepository().update(entity);

      expect(result, isA<User>());
      expect(result?.id, "user-1");
      expect(result?.login, "admin");
      expect(result?.firstName, "Admin");
      expect(result?.lastName, "User");
      expect(result?.email, "admin@sample.tech");
      expect(result?.activated, true);
      expect(result?.langKey, "en");
      expect(result?.createdBy, "system");
      expect(result?.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.lastModifiedBy, "admin");
      expect(result?.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(result?.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid user without accessToken when updateUser then return user fail", () async {
      expect(() async => await UserRepository().update(mockUserFullPayload), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null user when updateUser then return user fail", () async {
      TestUtils().setupAuthentication();

      expect(() async => await UserRepository().update(const User()), throwsA(isA<BadRequestException>()));
    });
  });

  group("User Repository deleteUser", () {
    test("Given valid userId when deleteUser then return void successfully", () async {
      TestUtils().setupAuthentication();

      expect(() async => await UserRepository().delete("user-1"), returnsNormally);
    });

    test("Given valid userId without accessToken when deleteUser then return void fail", () async {
      expect(() async => await UserRepository().delete("1"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null userId when deleteUser then return void fail", () async {
      TestUtils().setupAuthentication();

      expect(() async => await UserRepository().delete(""), throwsA(isA<BadRequestException>()));
    });
  });
}
