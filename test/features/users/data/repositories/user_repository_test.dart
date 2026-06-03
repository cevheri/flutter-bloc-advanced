import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/fake_data.dart';
import '../../../../support/test_env.dart';

void main() {
  late UserRepository repository;

  setUp(() {
    repository = UserRepository(TestEnv.apiClient());
  });

  group("User Repository getUsers", () {
    test("Given valid user when getUsers then return user list successfully", () async {
      TestEnv.authenticate();
      final result = await repository.list();
      expect(result, isA<Success<List<UserEntity>>>());
      expect((result as Success<List<UserEntity>>).data.length, 4);
    });

    test("Given valid user without accessToken when getUsers then return failure", () async {
      final result = await repository.list();
      expect(result, isA<Failure<List<UserEntity>>>());
    });
  });

  group("User Repository getUser", () {
    test("Given valid userId when getUser then return user successfully", () async {
      TestEnv.authenticate();
      final result = await repository.retrieve("user-1");

      expect(result, isA<Success<UserEntity>>());
      final data = (result as Success<UserEntity>).data;
      expect(data.id, "user-1");
      expect(data.login, "admin");
      expect(data.firstName, "Admin");
      expect(data.lastName, "User");
      expect(data.email, "admin@sample.tech");
      expect(data.activated, true);
      expect(data.langKey, "en");
      expect(data.createdBy, "system");
      expect(data.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.lastModifiedBy, "admin");
      expect(data.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid userId without accessToken when getUser then return failure", () async {
      final result = await repository.retrieve("1");
      expect(result, isA<Failure<UserEntity>>());
    });

    test("Given null userId when getUser then return validation failure", () async {
      TestEnv.authenticate();
      final result = await repository.retrieve("");
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });
  });

  group("User Repository getUserByLogin", () {
    test("Given valid login when getUserByLogin then return user successfully", () async {
      TestEnv.authenticate();
      final result = await repository.retrieveByLogin("username");

      expect(result, isA<Success<UserEntity>>());
      final data = (result as Success<UserEntity>).data;
      expect(data.id, "user-1");
      expect(data.login, "admin");
      expect(data.firstName, "Admin");
      expect(data.lastName, "User");
      expect(data.email, "admin@sample.tech");
      expect(data.activated, true);
      expect(data.langKey, "en");
      expect(data.createdBy, "system");
      expect(data.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.lastModifiedBy, "admin");
      expect(data.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid login without accessToken when getUserByLogin then return failure", () async {
      final result = await repository.retrieveByLogin("admin");
      expect(result, isA<Failure<UserEntity>>());
    });

    test("Given null login when getUserByLogin then return validation failure", () async {
      TestEnv.authenticate();
      final result = await repository.retrieveByLogin("");
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });
  });

  group("User Repository createUser", () {
    test("Given valid user when createUser then return user successfully", () async {
      TestEnv.authenticate();
      final entity = mockUserFullPayload;
      final result = await repository.create(entity);

      expect(result, isA<Success<UserEntity>>());
      final data = (result as Success<UserEntity>).data;
      expect(data.id, "user-1");
      expect(data.login, "admin");
      expect(data.firstName, "Admin");
      expect(data.lastName, "User");
      expect(data.email, "admin@sample.tech");
      expect(data.activated, true);
      expect(data.langKey, "en");
      expect(data.createdBy, "system");
      expect(data.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.lastModifiedBy, "admin");
      expect(data.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid user without accessToken when createUser then return failure", () async {
      final result = await repository.create(mockUserFullPayload);
      expect(result, isA<Failure<UserEntity>>());
    });

    test("Given null user when createUser then return validation failure", () async {
      TestEnv.authenticate();
      final result = await repository.create(const User());
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });

    test("Given null username when createUser then return validation failure", () async {
      TestEnv.authenticate();
      final result = await repository.create(const User(login: "admin"));
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });
  });

  group("User Repository listUser", () {
    test("Given valid range when listUser then return user list successfully", () async {
      TestEnv.authenticate();
      final result = await repository.list(page: 0, size: 10);

      expect(result, isA<Success<List<UserEntity>>>());
      expect((result as Success<List<UserEntity>>).data.length, 4);
    });

    test("Given valid range without accessToken when listUser then return failure", () async {
      final result = await repository.list(page: 0, size: 10);
      expect(result, isA<Failure<List<UserEntity>>>());
    });
  });

  group("User Repository findUserByAuthority", () {
    test("Given valid range and authority when findUserByAuthority then return user list successfully", () async {
      TestEnv.authenticate();
      final result = await repository.listByAuthority(0, 10, "ROLE_ADMIN");

      expect(result, isA<Success<List<UserEntity>>>());
      expect((result as Success<List<UserEntity>>).data.length, 4);
    });

    test("Given valid range and authority without accessToken when findUserByAuthority then return failure", () async {
      final result = await repository.listByAuthority(0, 10, "ROLE_ADMIN");
      expect(result, isA<Failure<List<UserEntity>>>());
    });
  });

  group("User Repository findUserByName", () {
    test("Given valid range, name and authority when findUserByName then return user list successfully", () async {
      TestEnv.authenticate();
      final result = await repository.listByNameAndRole(0, 10, "admin", "ROLE_ADMIN");

      expect(result, isA<Success<List<UserEntity>>>());
      expect((result as Success<List<UserEntity>>).data.length, 4);
    });

    test("Given valid range, name and authority without accessToken when findUserByName then return failure", () async {
      final result = await repository.listByNameAndRole(0, 10, "admin", "ROLE_ADMIN");
      expect(result, isA<Failure<List<UserEntity>>>());
    });
  });

  group("User Repository updateUser", () {
    test("Given valid user when updateUser then return user successfully", () async {
      TestEnv.authenticate();
      final entity = mockUserFullPayload;
      final result = await repository.update(entity);

      expect(result, isA<Success<UserEntity>>());
      final data = (result as Success<UserEntity>).data;
      expect(data.id, "user-1");
      expect(data.login, "admin");
      expect(data.firstName, "Admin");
      expect(data.lastName, "User");
      expect(data.email, "admin@sample.tech");
      expect(data.activated, true);
      expect(data.langKey, "en");
      expect(data.createdBy, "system");
      expect(data.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.lastModifiedBy, "admin");
      expect(data.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.authorities, ["ROLE_ADMIN", "ROLE_USER"]);
    });

    test("Given valid user without accessToken when updateUser then return failure", () async {
      final result = await repository.update(mockUserFullPayload);
      expect(result, isA<Failure<UserEntity>>());
    });

    test("Given null user when updateUser then return validation failure", () async {
      TestEnv.authenticate();
      final result = await repository.update(const User());
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });
  });

  group("User Repository deleteUser", () {
    test("Given valid userId when deleteUser then return success", () async {
      TestEnv.authenticate();
      final result = await repository.delete("user-1");
      expect(result, isA<Success<void>>());
    });

    test("Given valid userId without accessToken when deleteUser then return failure", () async {
      final result = await repository.delete("1");
      expect(result, isA<Failure<void>>());
    });

    test("Given null userId when deleteUser then return validation failure", () async {
      TestEnv.authenticate();
      final result = await repository.delete("");
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });
  });
}
