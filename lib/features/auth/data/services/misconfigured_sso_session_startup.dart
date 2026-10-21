import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_session_startup.dart';

/// The startup step of a misconfigured `oidc` build: it never uses the stored session, so the user starts signed out
/// and the login page shows [AppErrorCode.authOidcConfig].
///
/// A session that an earlier, correctly configured `oidc` build stored holds the provider's tokens. This build can
/// neither refresh nor end it at the provider, and restoring it would hide the misconfiguration from the user. The
/// session stays stored, so a corrected build can still restore it.
class MisconfiguredSsoSessionStartup implements ISsoSessionStartup {
  const MisconfiguredSsoSessionStartup();

  @override
  Future<SsoStartupResult> run() async => const SsoStartupSignInFailed(AppErrorCode.authOidcConfig);

  /// Nothing to give up: [run] answers at once, and this build has no automatic redirect gate.
  @override
  void giveUp() {}
}
