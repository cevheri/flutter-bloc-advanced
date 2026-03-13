import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';

class AuthenticateUserUseCase {
  const AuthenticateUserUseCase(this._repository);

  final IAuthRepository _repository;

  Future<Result<AuthTokenEntity>> call(AuthCredentialsEntity credentials) {
    return _repository.authenticate(credentials);
  }
}
