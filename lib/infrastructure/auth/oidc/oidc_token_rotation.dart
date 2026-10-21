import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

import 'oidc_client.dart';

/// The `oidc` mode's [TokenRotation]: a `refresh_token` grant at the provider's token endpoint, through [IOidcClient].
///
/// The package refreshes only a whole session, so this reads the rest of it, the access token, the ID token and the
/// access token's expiry, from the secure store itself. Like every [TokenRotation] it stores nothing.
///
/// The startup step and `TokenRefreshInterceptor` share one instance, and a refresh token is sent in at most one grant:
/// a provider with refresh token reuse detection revokes the whole session when a used one comes back. So the
/// rotations run one at a time, and each first checks that its refresh token is still unused. On web the browser tabs
/// each have an instance, and their rotations take turns at the cross-tab lock that both callers hold while they rotate
/// (`ITokenRefreshLock`).
final class OidcTokenRotation implements TokenRotation {
  OidcTokenRotation({required this._client, required this._secureStorage});

  static final _log = AppLogger.getLogger('OidcTokenRotation');

  final IOidcClient _client;
  final ISecureStorage _secureStorage;

  /// The end of the last rotation, which the next one waits for.
  Future<void> _previous = Future<void>.value();

  /// The refresh token of the last grant and its answer, kept only while that answer used the token up: a refusal, or
  /// tokens with a new refresh token. A rotation sent the same token gets that answer again without a grant.
  String? _spentRefreshToken;
  TokenRotationResult? _spentAnswer;

  /// Masks the spent refresh token, so a log line that prints this rotation does not print a credential.
  @override
  String toString() => 'OidcTokenRotation(spentRefreshToken: $secretMask)';

  /// Answers [RotationRefused] without a request when the stored access token, ID token or expiry is missing, since
  /// the session cannot be refreshed without them.
  ///
  /// A [refreshToken] that the last grant used up gets that grant's answer, so a caller that read it before the grant
  /// stores the same tokens or adopts the stored ones. A [refreshToken] that the store no longer holds, because another
  /// caller rotated or ended the session, gets [RotationUnavailable] without a request: the session is kept, and
  /// `TokenRefreshInterceptor` sends the request again with the stored tokens.
  @override
  Future<TokenRotationResult> rotate(String refreshToken) {
    final answer = _previous.then((_) => _rotateInTurn(refreshToken));
    _previous = answer.then<void>((_) {}, onError: (Object _) {});
    return answer;
  }

  Future<TokenRotationResult> _rotateInTurn(String refreshToken) async {
    final spentAnswer = _spentAnswer;
    if (spentAnswer != null && refreshToken == _spentRefreshToken) {
      _log.info('The refresh token was already sent: its answer is reused, no grant is sent');
      return spentAnswer;
    }
    final storedRefreshToken = await _secureStorage.read(SecureStorageKeys.refreshToken.key);
    if (storedRefreshToken != refreshToken) {
      _log.info('The refresh token is no longer the stored one: no grant is sent, the stored session is kept');
      return const RotationUnavailable();
    }
    final accessToken = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
    final idToken = await _secureStorage.read(SecureStorageKeys.oidcIdToken.key);
    final expiresAt = readAccessTokenExpiry(await _secureStorage.read(SecureStorageKeys.accessTokenExpiresAt.key));
    final hasBearer = accessToken != null && accessToken.isNotEmpty;
    final hasIdentity = idToken != null && idToken.isNotEmpty;
    if (!hasBearer || !hasIdentity || expiresAt == null) {
      _log.warn('The stored session cannot be refreshed: bearer stored {}, ID token stored {}, expiry stored {}', [
        hasBearer,
        hasIdentity,
        expiresAt != null,
      ]);
      return const RotationRefused();
    }
    final result = await _client.refresh(
      refreshToken: refreshToken,
      idToken: idToken,
      accessToken: accessToken,
      accessTokenExpiresAt: expiresAt,
    );
    final spent = switch (result) {
      // A provider that does not rotate refresh tokens answers none, or the same one: the token stays the stored one
      // and is traded again when the new access token expires.
      TokensRotated(refreshToken: final newRefreshToken) =>
        newRefreshToken != null && newRefreshToken.isNotEmpty && newRefreshToken != refreshToken,
      RotationRefused() => true,
      // The provider may not have seen the token, so it can be sent again.
      RotationUnavailable() => false,
    };
    _spentRefreshToken = spent ? refreshToken : null;
    _spentAnswer = spent ? result : null;
    return result;
  }
}
