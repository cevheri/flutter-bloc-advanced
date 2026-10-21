import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';

/// How the startup step of an `oidc` build settled the session, before the stored session is read.
sealed class SsoStartupResult {
  const SsoStartupResult();
}

/// The stored session is read as it is: it is still valid, it was refreshed, or the provider could not be reached.
final class SsoStartupUseStoredSession extends SsoStartupResult {
  const SsoStartupUseStoredSession();
}

/// A same-tab web sign-in completed at startup, and its session is stored.
final class SsoStartupSignedIn extends SsoStartupResult {
  const SsoStartupSignedIn({required this.roles});

  final List<String> roles;
}

/// A same-tab web sign-in failed at startup; [errorCode] is shown on the login page.
final class SsoStartupSignInFailed extends SsoStartupResult {
  const SsoStartupSignInFailed(this.errorCode);

  final AppErrorCode errorCode;
}

/// The stored session could not be kept, and is cleared: the user starts signed out.
final class SsoStartupSessionEnded extends SsoStartupResult {
  const SsoStartupSessionEnded();
}

/// The startup step of an `oidc` build: it completes a pending same-tab web sign-in, and refreshes an expired stored
/// access token, before the router picks the first screen.
abstract interface class ISsoSessionStartup {
  Future<SsoStartupResult> run();

  /// The caller gave up on [run]: it did not answer in time, and may still be completing a sign-in, or it failed.
  /// Closes the automatic redirect gate, so a redirect can neither race that completion nor follow the failure.
  void giveUp();
}
