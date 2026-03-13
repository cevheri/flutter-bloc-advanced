import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class RegisterAccountUseCase {
  const RegisterAccountUseCase(this._repository);

  final IAccountRepository _repository;

  Future<Result<UserEntity>> call(UserEntity user) {
    return _repository.register(user);
  }
}
