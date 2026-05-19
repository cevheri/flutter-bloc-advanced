import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';

class PersistAuthSessionUseCase {
  const PersistAuthSessionUseCase(this._repository);

  final IAuthSessionRepository _repository;

  Future<Result<void>> call(AuthSession session) => _repository.persist(session);
}
