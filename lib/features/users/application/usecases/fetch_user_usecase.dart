import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class FetchUserUseCase {
  const FetchUserUseCase(this._repository);

  final IUserRepository _repository;

  Future<Result<UserEntity>> call(String id) {
    return _repository.retrieve(id);
  }
}
