import 'package:flutter_bloc_advance/features/auth/application/usecases/sign_in_with_sso_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/sso_sign_in_result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/sso_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSsoAuthRepository implements ISsoAuthRepository {
  SsoSignInResult result = const SsoSignInCancelled();
  final signIns = <({String? webReturnPath, String browserDoneMessage})>[];

  @override
  Future<SsoSignInResult> signIn({String? webReturnPath, required String browserDoneMessage}) async {
    signIns.add((webReturnPath: webReturnPath, browserDoneMessage: browserDoneMessage));
    return result;
  }

  @override
  Future<SsoSignInResult?> completePendingSignIn() => throw UnimplementedError('the use case only signs in');
}

void main() {
  group('SignInWithSsoUseCase', () {
    test('signs in through the repository with the return path and the browser message', () async {
      final repository = _FakeSsoAuthRepository();

      await SignInWithSsoUseCase(repository)(webReturnPath: '/users', browserDoneMessage: 'done');

      expect(repository.signIns, [(webReturnPath: '/users', browserDoneMessage: 'done')]);
    });

    test('answers the result of the repository unchanged', () async {
      const succeeded = SsoSignInSucceeded(username: 'jdoe', roles: ['ROLE_USER']);
      final repository = _FakeSsoAuthRepository()..result = succeeded;

      expect(await SignInWithSsoUseCase(repository)(browserDoneMessage: 'done'), same(succeeded));
    });
  });
}
