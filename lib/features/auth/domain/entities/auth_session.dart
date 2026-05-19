import 'package:equatable/equatable.dart';

/// Value object representing a fully-formed authenticated session.
///
/// Bundles the JWT, optional refresh token, the resolved username, and
/// the user's authorities into one atom that the application layer can
/// hand to a single persistence use case. The session is what gets
/// written; the underlying storage shape is the repository's concern.
class AuthSession extends Equatable {
  const AuthSession({required this.idToken, required this.username, this.refreshToken, this.roles = const []});

  final String? idToken;
  final String? refreshToken;
  final String username;
  final List<String> roles;

  @override
  List<Object?> get props => [idToken, refreshToken, username, roles];
}
