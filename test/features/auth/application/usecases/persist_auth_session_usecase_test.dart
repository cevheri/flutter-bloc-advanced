import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/persist_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthSessionRepository implements IAuthSessionRepository {
  Result<void> persistResult = const Success(null);
  AuthSession? last;

  @override
  Future<Result<void>> persist(AuthSession session) async {
    last = session;
    return persistResult;
  }

  @override
  Future<Result<void>> clear() async => const Success(null);
}

void main() {
  group('PersistAuthSessionUseCase', () {
    test('forwards the session to the repository and returns its Result', () async {
      final repo = _FakeAuthSessionRepository();
      final useCase = PersistAuthSessionUseCase(repo);
      const session = AuthSession(idToken: 'tok', username: 'u', roles: ['ROLE_USER']);

      final result = await useCase(session);

      expect(result, isA<Success<void>>());
      expect(repo.last, session);
    });

    test('propagates a repository failure unchanged', () async {
      final repo = _FakeAuthSessionRepository()..persistResult = const Failure(UnknownError('disk full'));
      final useCase = PersistAuthSessionUseCase(repo);

      final result = await useCase(const AuthSession(idToken: 'tok', username: 'u'));

      expect(result, isA<Failure<void>>());
      expect((result as Failure).error.message, contains('disk full'));
    });
  });
}
