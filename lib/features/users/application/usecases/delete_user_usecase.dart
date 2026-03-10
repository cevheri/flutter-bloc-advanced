import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';

class DeleteUserUseCase {
  const DeleteUserUseCase(this._repository);

  final IUserRepository _repository;

  Future<void> call(String id) {
    return _repository.delete(id);
  }
}
