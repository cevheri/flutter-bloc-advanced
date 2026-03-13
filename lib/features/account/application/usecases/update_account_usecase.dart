import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class UpdateAccountUseCase {
  const UpdateAccountUseCase(this._repository);

  final IAccountRepository _repository;

  Future<Result<UserEntity>> call(UserEntity user) {
    return _repository.update(user);
  }
}
