import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/models/authority.dart';

abstract class IAuthorityRepository {
  Future<Result<Authority>> create(Authority authority);

  Future<Result<List<String>>> list();

  Future<Result<Authority>> retrieve(String id);

  Future<Result<void>> delete(String id);
}
