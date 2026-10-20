import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';

/// Login of the protected admin account that the system must never
/// delete. The API deletes a user by login (`DELETE /admin/users/{login}`),
/// so the rule checks the login too. Owned by the use case (single source
/// of truth for the rule) so callers can't bypass it by going straight to
/// the repository.
const String _protectedAdminLogin = 'admin';

class DeleteUserUseCase {
  const DeleteUserUseCase(this._repository);

  final IUserRepository _repository;

  Future<Result<void>> call(String login) async {
    if (login == _protectedAdminLogin) {
      return Failure(ValidationError('Admin user cannot be deleted', code: AppErrorCode.userCannotDeleteAdmin.key));
    }
    return _repository.delete(login);
  }
}
