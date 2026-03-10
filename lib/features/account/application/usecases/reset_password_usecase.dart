import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final IAccountRepository _repository;

  Future<int> call(String email) {
    return _repository.resetPassword(email);
  }
}
