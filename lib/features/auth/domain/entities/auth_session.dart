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
class AuthSession extends Equatable {
  const AuthSession({required this.idToken, required this.username, this.refreshToken, this.roles = const []})
    : assert(idToken != '', 'idToken must be non-empty');

  final String idToken;
  final String? refreshToken;
  final String username;
  final List<String> roles;

  @override
  List<Object?> get props => [idToken, refreshToken, username, roles];

  /// Tokens are masked so this is safe to embed in log output, even if
  /// `Equatable.stringify` is later flipped on for diagnostic reasons.
  @override
  String toString() =>
      'AuthSession('
      'idToken: ${LogSanitizer.maskToken(idToken)}, '
      'refreshToken: ${LogSanitizer.maskToken(refreshToken)}, '
      'username: $username, '
      'roles: $roles)';
}
