import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';

/// Removes the stored session, as a logout does, without ending it anywhere else.
class ClearAuthSessionUseCase {
  const ClearAuthSessionUseCase(this._repository);

  final IAuthSessionRepository _repository;

  Future<Result<void>> call() => _repository.clear();
}
