import 'package:flutter_bloc_advance/features/auth/domain/entities/sso_sign_in_result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/sso_auth_repository.dart';

class SignInWithSsoUseCase {
  const SignInWithSsoUseCase(this._repository);

  final ISsoAuthRepository _repository;

  Future<SsoSignInResult> call({String? webReturnPath, required String browserDoneMessage}) =>
      _repository.signIn(webReturnPath: webReturnPath, browserDoneMessage: browserDoneMessage);
}
