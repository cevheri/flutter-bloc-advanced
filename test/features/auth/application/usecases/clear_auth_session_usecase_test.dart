import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/clear_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthSessionRepository implements IAuthSessionRepository {
  Result<void> clearResult = const Success(null);
  int clears = 0;

  @override
  Future<Result<void>> persist(AuthSession session) async => throw UnimplementedError('the use case only clears');

  @override
  Future<Result<void>> clear() async {
    clears++;
    return clearResult;
  }
}

void main() {
  group('ClearAuthSessionUseCase', () {
    test('clears the stored session through the repository and returns its Result', () async {
      final repo = _FakeAuthSessionRepository();

      final result = await ClearAuthSessionUseCase(repo)();

      expect(result, isA<Success<void>>());
      expect(repo.clears, 1);
    });

    test('propagates a repository failure unchanged', () async {
      final repo = _FakeAuthSessionRepository()..clearResult = const Failure(UnknownError('Session clear failed'));

      final result = await ClearAuthSessionUseCase(repo)();

      expect(result, isA<Failure<void>>());
      expect((result as Failure).error.message, 'Session clear failed');
    });
  });
}
