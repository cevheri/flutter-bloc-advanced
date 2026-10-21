import 'package:flutter_bloc_advance/features/auth/domain/entities/sso_sign_in_result.dart';

/// Signs the user in through the OpenID Connect provider and stores the session the sign-in gives.
abstract class ISsoAuthRepository {
  /// Signs the user in through the provider's page. On web the tab leaves for the provider and lands on
  /// [webReturnPath] when it comes back; [browserDoneMessage] is the page a desktop browser shows once the app has the
  /// answer.
  Future<SsoSignInResult> signIn({String? webReturnPath, required String browserDoneMessage});

  /// Completes a same-tab web sign-in after the tab came back from the provider. Null when none is pending.
  Future<SsoSignInResult?> completePendingSignIn();
}
