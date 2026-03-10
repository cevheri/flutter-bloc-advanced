import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

abstract class IUserRepository {
  Future<UserEntity?> retrieve(String id);

  Future<UserEntity?> retrieveByLogin(String login);

  Future<UserEntity?> create(UserEntity user);

  Future<UserEntity?> update(UserEntity user);

  Future<List<UserEntity>> list({int page = 0, int size = 10, List<String> sort = const ['id,desc']});

  Future<List<UserEntity>> listByAuthority(int page, int size, String authority);

  Future<List<UserEntity>> listByNameAndRole(int page, int size, String name, String authority);

  Future<void> delete(String id);
}
