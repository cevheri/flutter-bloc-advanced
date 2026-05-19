import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);

  final IAccountRepository _repository;

  Future<Result<void>> call(PasswordChangeDTO request) async {
    final current = request.currentPassword;
    final next = request.newPassword;
    if (current == null || current.isEmpty || next == null || next.isEmpty) {
      return const Failure(ValidationError('Both current and new password are required'));
    }
    if (current == next) {
      return const Failure(ValidationError('New password must be different from current password'));
    }
    return _repository.changePassword(request);
  }
}
