import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

abstract class IUserRepository {
  Future<Result<UserEntity>> retrieve(String id);

  Future<Result<UserEntity>> retrieveByLogin(String login);

  Future<Result<UserEntity>> create(UserEntity user);

  Future<Result<UserEntity>> update(UserEntity user);

  Future<Result<List<UserEntity>>> list({int page = 0, int size = 10, List<String> sort = const ['id,desc']});

  Future<Result<List<UserEntity>>> listByAuthority(int page, int size, String authority);

  Future<Result<List<UserEntity>>> listByNameAndRole(int page, int size, String name, String authority);

  Future<Result<void>> delete(String id);
}
