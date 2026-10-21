import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';

/// How a single sign-on ended, once the provider's answer has become the app's session.
sealed class SsoSignInResult {
  const SsoSignInResult();
}

/// The session is stored. [username] and [roles] are what the login page signs the user in with.
final class SsoSignInSucceeded extends SsoSignInResult {
  const SsoSignInSucceeded({required this.username, required this.roles});

  final String username;
  final List<String> roles;
}

/// The user left the provider page without signing in.
final class SsoSignInCancelled extends SsoSignInResult {
  const SsoSignInCancelled();
}

/// The sign-in failed, or the account may not use the app; nothing is stored. [errorCode] is shown to the user.
final class SsoSignInRejected extends SsoSignInResult {
  const SsoSignInRejected(this.errorCode);

  final AppErrorCode errorCode;
}

/// The web tab is on its way to the provider; the sign-in completes after the tab comes back.
final class SsoSignInNavigatedAway extends SsoSignInResult {
  const SsoSignInNavigatedAway();
}
