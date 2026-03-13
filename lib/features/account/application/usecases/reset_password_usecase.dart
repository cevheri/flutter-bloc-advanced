import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final IAccountRepository _repository;

  Future<Result<void>> call(String email) {
    return _repository.resetPassword(email);
  }
}
