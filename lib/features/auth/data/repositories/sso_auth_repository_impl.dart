import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/core/security/oidc_role_mapping.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/sso_sign_in_result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/sso_auth_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';

/// [ISsoAuthRepository] over [IOidcClient].
///
/// A sign-in becomes a session only when the verified ID token carries a string `sub` and `iss` and maps to an allowed
/// role. The session is then persisted through [IAuthSessionRepository] like a password sign-in: the access token is
/// the bearer, and the OIDC ID token and the access token's expiry go with it. The username is the `email` claim, else
/// `preferred_username`, else `sub`.
class SsoAuthRepository implements ISsoAuthRepository {
  SsoAuthRepository({required this._client, required this._sessionRepository, required this._settings});

  static final _log = AppLogger.getLogger('SsoAuthRepository');

  final IOidcClient _client;
  final IAuthSessionRepository _sessionRepository;
  final OidcSettings _settings;

  @override
  Future<SsoSignInResult> signIn({String? webReturnPath, required String browserDoneMessage}) async =>
      _toResult(await _client.signIn(webReturnPath: webReturnPath, browserDoneMessage: browserDoneMessage));

  @override
  Future<SsoSignInResult?> completePendingSignIn() async {
    final outcome = await _client.completePendingSignIn();
    return outcome == null ? null : _toResult(outcome);
  }

  Future<SsoSignInResult> _toResult(OidcSignInOutcome outcome) async => switch (outcome) {
    OidcSignedIn(:final tokens, :final claims) => await _persist(tokens, claims),
    OidcSignInCancelled() => const SsoSignInCancelled(),
    OidcSignInNavigatedAway() => const SsoSignInNavigatedAway(),
    OidcSignInFailed(failure: OidcFailure.discovery) => const SsoSignInRejected(AppErrorCode.authOidcDiscovery),
    OidcSignInFailed(failure: OidcFailure.failed) => const SsoSignInRejected(AppErrorCode.authOidcFailed),
  };

  Future<SsoSignInResult> _persist(OidcTokens tokens, Map<String, Object?> claims) async {
    final subject = _nonEmptyString(claims['sub']);
    if (subject == null || _nonEmptyString(claims['iss']) == null) {
      _log.warn('The ID token has no string sub or iss, so the sign-in is refused');
      return const SsoSignInRejected(AppErrorCode.authOidcNoClaims);
    }
    final role = mapOidcRole(
      claims,
      roleClaim: _settings.roleClaim,
      adminRoles: _settings.adminRoles,
      userRoles: _settings.userRoles,
    );
    if (role == null) {
      _log.warn('The account holds no allowed role in claim {}, so the sign-in is refused', [_settings.roleClaim]);
      return const SsoSignInRejected(AppErrorCode.authOidcNoRole);
    }
    final username = _nonEmptyString(claims['email']) ?? _nonEmptyString(claims['preferred_username']) ?? subject;
    final roles = appRolesFor(role);
    final persisted = await _sessionRepository.persist(
      AuthSession(
        idToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        username: username,
        roles: roles,
        oidcIdToken: tokens.idToken,
        accessTokenExpiresAt: tokens.accessTokenExpiresAt,
      ),
    );
    switch (persisted) {
      case Success():
        _log.info('Signed in through the identity provider as {} with role {}', [username, role.name]);
        return SsoSignInSucceeded(username: username, roles: roles);
      case Failure(:final error):
        _log.error('The single sign-on session could not be stored: {}', [error.message]);
        return const SsoSignInRejected(AppErrorCode.authSessionPersistFailed);
    }
  }

  static String? _nonEmptyString(Object? value) => value is String && value.isNotEmpty ? value : null;
}
