import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_env.dart';

void main() {
  late AuthorityRepositoryImpl repository;

  //region setup
  setUp(() {
    repository = AuthorityRepositoryImpl(TestEnv.apiClient());
  });
  //endregion setup

  //getAuthorities
  group("AuthorityRepository list", () {
    test("Given valid when getAuthorities then return authorities successfully", () async {
      TestEnv.authenticate();
      final result = await repository.list();

      expect(result, isA<Success<List<String>>>());
      final data = (result as Success<List<String>>).data;
      expect(data.length, 2);
      expect(data[0], "ROLE_USER");
      expect(data[1], "ROLE_ADMIN");
    });
    test("Given valid without AccessToken when getAuthorities then return failure", () async {
      final result = await repository.list();
      expect(result, isA<Failure<List<String>>>());
    });
  });
}
