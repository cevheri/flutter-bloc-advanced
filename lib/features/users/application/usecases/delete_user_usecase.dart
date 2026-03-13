import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';

class DeleteUserUseCase {
  const DeleteUserUseCase(this._repository);

  final IUserRepository _repository;

  Future<Result<void>> call(String id) {
    return _repository.delete(id);
  }
}
