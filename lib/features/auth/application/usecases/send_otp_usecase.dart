import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';

class SendOtpUseCase {
  const SendOtpUseCase(this._repository);

  final IAuthRepository _repository;

  Future<Result<void>> call(SendOtpEntity request) {
    return _repository.sendOtp(request);
  }
}
