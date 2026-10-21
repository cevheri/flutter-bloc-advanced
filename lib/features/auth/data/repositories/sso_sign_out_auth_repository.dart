import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// The [IAuthRepository] of an `oidc` build, whose logout also ends the user's session at the identity provider.
///
/// Only a logout the user starts comes here: an idle timeout or an unrefreshable 401 clears the local session through
/// `SessionCubit`, since a provider logout needs a browser and the user is not there. Everything else is [_inner]'s.
class SsoSignOutAuthRepository implements IAuthRepository {
  SsoSignOutAuthRepository({
    required this._inner,
    required this._client,
    required this._secureStorage,
    required this._settings,
  });

  static final _log = AppLogger.getLogger('SsoSignOutAuthRepository');

  final IAuthRepository _inner;
  final IOidcClient _client;
  final ISecureStorage _secureStorage;
  final OidcSettings _settings;

  @override
  Future<Result<AuthTokenEntity>> authenticate(AuthCredentialsEntity userJWT) => _inner.authenticate(userJWT);

  @override
  Future<Result<void>> sendOtp(SendOtpEntity request) => _inner.sendOtp(request);

  @override
  Future<Result<AuthTokenEntity>> verifyOtp(VerifyOtpEntity request) => _inner.verifyOtp(request);

  /// Reads the stored ID token, clears the local session through [_inner], then ends the provider session.
  ///
  /// The ID token is sent as `id_token_hint` when `OIDC_LOGOUT_HINT` is on. It is written, rolled back and wiped
  /// together with the session it belongs to, so it is always the current session's, and it is sent even when it has
  /// expired: Keycloak gives it the access token's short life and still accepts it at its logout endpoint.
  ///
  /// The answer is [_inner]'s, except that a failed provider logout after a clean wipe is an [AuthError] with
  /// [AppErrorCode.authOidcLogoutIncomplete]. A failed wipe wins over it: data left on this device matters more.
  @override
  Future<Result<void>> logout() async {
    String? idToken;
    try {
      idToken = await _secureStorage.read(SecureStorageKeys.oidcIdToken.key);
    } catch (error) {
      // Only the type: the error of a secure store may carry what it holds.
      _log.warn('logout: the stored ID token could not be read, so the provider logout sends no hint: {}', [
        error.runtimeType,
      ]);
    }
    final cleared = await _inner.logout();
    final outcome = await _client.endProviderSession(idTokenHint: _settings.logoutHint ? idToken : null);
    switch (outcome) {
      case ProviderLogoutFailed():
        if (cleared is Failure) return cleared;
        _log.warn('logout: signed out of the app, but the session at the identity provider may still be active');
        return Failure(AuthError('provider logout incomplete', code: AppErrorCode.authOidcLogoutIncomplete.key));
      case ProviderSessionEnded() || NoProviderLogout() || ProviderLogoutNavigatedAway():
        return cleared;
    }
  }
}
