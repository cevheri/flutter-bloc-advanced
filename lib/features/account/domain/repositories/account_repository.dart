import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

abstract class IAccountRepository {
  Future<Result<UserEntity>> register(UserEntity newUser);

  Future<Result<void>> changePassword(PasswordChangeDTO passwordChangeDTO);

  Future<Result<void>> resetPassword(String mailAddress);

  Future<Result<UserEntity>> getAccount();

  Future<Result<UserEntity>> update(UserEntity user);

  Future<Result<void>> delete(String id);
}
