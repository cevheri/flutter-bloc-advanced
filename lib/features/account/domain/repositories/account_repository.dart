import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

abstract class IAccountRepository {
  Future<UserEntity?> register(UserEntity? newUser);

  Future<int> changePassword(PasswordChangeDTO? passwordChangeDTO);

  Future<int> resetPassword(String mailAddress);

  Future<UserEntity> getAccount();

  Future<UserEntity> update(UserEntity? user);

  Future<bool> delete(String id);
}
