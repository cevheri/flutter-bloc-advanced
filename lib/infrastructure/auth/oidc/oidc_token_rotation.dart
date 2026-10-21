import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

import 'oidc_client.dart';

/// The `oidc` mode's [TokenRotation]: a `refresh_token` grant at the provider's token endpoint, through [IOidcClient].
///
/// The package refreshes only a whole session, so this reads the rest of it, the access token, the ID token and the
/// access token's expiry, from the secure store itself. Like every [TokenRotation] it stores nothing.
final class OidcTokenRotation implements TokenRotation {
  OidcTokenRotation({required this._client, required this._secureStorage});

  static final _log = AppLogger.getLogger('OidcTokenRotation');

  final IOidcClient _client;
  final ISecureStorage _secureStorage;

  /// Answers [RotationRefused] without a request when the stored access token, ID token or expiry is missing, since
  /// the session cannot be refreshed without them.
  @override
  Future<TokenRotationResult> rotate(String refreshToken) async {
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
    return _client.refresh(
      refreshToken: refreshToken,
      idToken: idToken,
      accessToken: accessToken,
      accessTokenExpiresAt: expiresAt,
    );
  }
}
