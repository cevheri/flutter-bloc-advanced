import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class SaveUserUseCase {
  const SaveUserUseCase(this._repository);

  final IUserRepository _repository;

  Future<Result<UserEntity>> call(UserEntity user) {
    if (user.id == null) {
      return _repository.create(user);
    }
    return _repository.update(user);
  }
}
