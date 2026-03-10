import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final IAuthRepository _repository;

  Future<void> call() {
    return _repository.logout();
  }
}
