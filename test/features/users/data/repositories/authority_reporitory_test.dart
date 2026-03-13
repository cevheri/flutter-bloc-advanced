import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/models/authority.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
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

  //createAuthority
  group("AuthorityRepository Create success", () {
    test("Given valid authority when create then return authority successfully", () async {
      TestUtils().setupAuthentication();
      const entity = mockAuthorityPayload;
      final result = await AuthorityRepositoryImpl().create(entity);

      expect(result, isA<Success<Authority>>());
      expect((result as Success<Authority>).data.name, "ROLE_USER");
    });
    test("Given valid authority without AccessToken when create then return failure", () async {
      const entity = mockAuthorityPayload;
      final result = await AuthorityRepositoryImpl().create(entity);
      expect(result, isA<Failure<Authority>>());
    });

    test("Given null authority when create then return validation failure", () async {
      final result = await AuthorityRepositoryImpl().create(const Authority());
      expect(result, isA<Failure<Authority>>());
      expect((result as Failure<Authority>).error, isA<ValidationError>());
    });
    test("Given empty authority when create then return validation failure", () async {
      final result = await AuthorityRepositoryImpl().create(const Authority(name: ""));
      expect(result, isA<Failure<Authority>>());
      expect((result as Failure<Authority>).error, isA<ValidationError>());
    });
  });

  //getAuthorities
  group("AuthorityRepository Get success", () {
    test("Given valid when getAuthorities then return authorities successfully", () async {
      TestUtils().setupAuthentication();
      final result = await AuthorityRepositoryImpl().list();

      expect(result, isA<Success<List<String>>>());
      final data = (result as Success<List<String>>).data;
      expect(data.length, 2);
      expect(data[0], "ROLE_USER");
      expect(data[1], "ROLE_ADMIN");
    });
    test("Given valid without AccessToken when getAuthorities then return failure", () async {
      final result = await AuthorityRepositoryImpl().list();
      expect(result, isA<Failure<List<String>>>());
    });
  });

  //getAuthority
  group("AuthorityRepository Get success", () {
    test("Given valid id when getAuthority then return authority successfully", () async {
      TestUtils().setupAuthentication();
      final result = await AuthorityRepositoryImpl().retrieve("1");

      expect(result, isA<Success<Authority>>());
      expect((result as Success<Authority>).data.name, "ROLE_USER");
    });
    test("Given valid id without AccessToken when getAuthority then return failure", () async {
      final result = await AuthorityRepositoryImpl().retrieve("1");
      expect(result, isA<Failure<Authority>>());
    });

    test("Given null id when getAuthority then return validation failure", () async {
      final result = await AuthorityRepositoryImpl().retrieve("");
      expect(result, isA<Failure<Authority>>());
      expect((result as Failure<Authority>).error, isA<ValidationError>());
    });
  });

  //deleteAuthority
  group("AuthorityRepository Delete success", () {
    test("Given valid id when deleteAuthority then return successful", () async {
      TestUtils().setupAuthentication();
      final result = await AuthorityRepositoryImpl().delete("1");
      expect(result, isA<Success<void>>());
    });
    test("Given valid id without AccessToken when deleteAuthority then return failure", () async {
      final result = await AuthorityRepositoryImpl().delete("1");
      expect(result, isA<Failure<void>>());
    });

    test("Given null id when deleteAuthority then return validation failure", () async {
      final result = await AuthorityRepositoryImpl().delete("");
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });
  });
}
