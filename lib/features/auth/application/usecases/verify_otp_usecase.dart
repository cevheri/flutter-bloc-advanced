import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final IAuthRepository _repository;

  Future<AuthTokenEntity?> call(VerifyOtpEntity request) {
    return _repository.verifyOtp(request);
  }
}
