import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);

  final IAccountRepository _repository;

  Future<int> call(PasswordChangeDTO request) {
    return _repository.changePassword(request);
  }
}
