import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/models/authority.dart';
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
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

  //createAuthority
  group("AuthorityRepository Create success", () {
    test("Given valid authority when create then return authority successfully", () async {
      TestUtils().setupAuthentication();
      final newAuthority = mockAuthorityPayload;
      final result = await AuthorityRepository().createAuthority(newAuthority);

      expect(result, isA<Authority>());
      expect(result?.name, "ROLE_USER");
    });
    test("Given valid authority without AccessToken when create then return authority fail", () async {
      final newAuthority = mockAuthorityPayload;
      expect(() async => await AuthorityRepository().createAuthority(newAuthority), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null authority when create then return authority fail", () async {
      expect(() async => await AuthorityRepository().createAuthority(Authority()), throwsA(isA<BadRequestException>()));
    });
    test("Given null authority when create then return authority fail", () async {
      expect(() async => await AuthorityRepository().createAuthority(Authority(name: "")), throwsA(isA<BadRequestException>()));
    });
  });

  //getAuthorities
  group("AuthorityRepository Get success", () {
    test("Given valid when getAuthorities then return authorities successfully", () async {
      TestUtils().setupAuthentication();
      final result = await AuthorityRepository().getAuthorities();

      expect(result, isA<List>());
      expect(result.length, 2);
      expect(result[0], "ROLE_USER");
      expect(result[1], "ROLE_ADMIN");
    });
    test("Given valid without AccessToken when getAuthorities then return authorities fail", () async {
      expect(() async => await AuthorityRepository().getAuthorities(), throwsA(isA<UnauthorizedException>()));
    });
  });

  //getAuthority
  group("AuthorityRepository Get success", () {
    test("Given valid id when getAuthority then return authority successfully", () async {
      TestUtils().setupAuthentication();
      final result = await AuthorityRepository().getAuthority("1");

      expect(result, isA<Authority>());
      expect(result?.name, "ROLE_USER");
    });
    test("Given valid id without AccessToken when getAuthority then return authority fail", () async {
      expect(() async => await AuthorityRepository().getAuthority("1"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null id when getAuthority then return authority fail", () async {
      expect(() async => await AuthorityRepository().getAuthority(""), throwsA(isA<BadRequestException>()));
    });
  });

  //deleteAuthority
  group("AuthorityRepository Delete success", () {
    test("Given valid id when deleteAuthority then return successful", () async {
      TestUtils().setupAuthentication();
      await AuthorityRepository().deleteAuthority("1");
    });
    test("Given valid id without AccessToken when deleteAuthority then return fail", () async {
      expect(() async => await AuthorityRepository().deleteAuthority("1"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null id when deleteAuthority then return fail", () async {
      expect(() async => await AuthorityRepository().deleteAuthority(""), throwsA(isA<BadRequestException>()));
    });
  });
}
