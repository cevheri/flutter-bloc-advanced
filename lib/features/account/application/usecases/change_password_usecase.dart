import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
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
      return Failure(
        ValidationError('Both current and new password are required', code: AppErrorCode.accountPasswordRequired.key),
      );
    }
    if (current == next) {
      return Failure(
        ValidationError(
          'New password must be different from current password',
          code: AppErrorCode.accountPasswordsSame.key,
        ),
      );
    }
    return _repository.changePassword(request);
  }
}
