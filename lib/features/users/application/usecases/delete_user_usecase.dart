import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';

/// Hard-coded id of the protected admin account that the system must
/// never delete. Owned by the use case (single source of truth for the
/// rule) so callers can't bypass it by going straight to the repository.
const String _protectedAdminUserId = 'user-1';

class DeleteUserUseCase {
  const DeleteUserUseCase(this._repository);

  final IUserRepository _repository;

  Future<Result<void>> call(String id) async {
    if (id == _protectedAdminUserId) {
      return const Failure(ValidationError('Admin user cannot be deleted', code: 'user.cannot_delete_admin'));
    }
    return _repository.delete(id);
  }
}
