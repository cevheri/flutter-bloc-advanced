import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final IAuthRepository _repository;

  Future<Result<void>> call() {
    return _repository.logout();
  }
}
