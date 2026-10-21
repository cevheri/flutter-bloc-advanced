import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';

/// Value object representing a fully-formed authenticated session.
///
/// Bundles the JWT, optional refresh token, the resolved username, and
/// the user's authorities into one atom that the application layer can
/// hand to a single persistence use case. The session is what gets
/// written; the underlying storage shape is the repository's concern.
///
/// [idToken] is non-nullable by contract — callers must validate the
/// token before constructing the session (see `AuthTokenEntity.isValid`).
///
/// An `oidc` sign-in also carries [oidcIdToken], the provider's ID token,
/// and [accessTokenExpiresAt], the access token's expiry from the token
/// response. In `jwt` mode both stay null.
class AuthSession extends Equatable {
  const AuthSession({
    required this.idToken,
    required this.username,
    this.refreshToken,
    this.roles = const [],
    this.oidcIdToken,
    this.accessTokenExpiresAt,
  }) : assert(idToken != '', 'idToken must be non-empty');

  final String idToken;
  final String? refreshToken;
  final String username;
  final List<String> roles;
  final String? oidcIdToken;
  final DateTime? accessTokenExpiresAt;

  @override
  List<Object?> get props => [idToken, refreshToken, username, roles, oidcIdToken, accessTokenExpiresAt];

  /// Whether this is the session of an `oidc` sign-in that carries the
  /// provider's ID token, outside [toString], which names the token only
  /// inside `maskToken`.
  bool get _hasOidcIdToken => oidcIdToken != null;

  /// Tokens are masked so this is safe to embed in log output. An OIDC
  /// field that is null is left out, so a `jwt` session prints as it did
  /// before the fields existed.
  @override
  String toString() =>
      'AuthSession('
      'idToken: ${maskToken(idToken)}, '
      'refreshToken: ${maskToken(refreshToken)}, '
      'username: $username, '
      'roles: $roles'
      '${_hasOidcIdToken ? ', oidcIdToken: ${maskToken(oidcIdToken)}' : ''}'
      '${accessTokenExpiresAt == null ? '' : ', accessTokenExpiresAt: $accessTokenExpiresAt'})';
}
