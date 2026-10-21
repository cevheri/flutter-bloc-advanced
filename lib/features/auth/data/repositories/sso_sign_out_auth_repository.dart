import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/sso_sign_out_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// The [IAuthRepository] of an `oidc` build, whose logout also ends the user's session at the identity provider.
///
/// Only a logout the user starts comes here: an idle timeout or an unrefreshable 401 clears the local session through
/// `SessionCubit`, since a provider logout needs a browser and the user is not there. Everything else is [_inner]'s.
/// The app signs out through [signOut], which answers before the provider logout has ended.
class SsoSignOutAuthRepository implements IAuthRepository, ISsoSignOutRepository {
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

  /// Reads the stored ID token, clears the local session through [_inner], starts the provider logout, and answers
  /// [_inner]'s result as [SsoSignOut.cleared] without waiting for the provider.
  ///
  /// The ID token is sent as `id_token_hint` when `OIDC_LOGOUT_HINT` is on. It is written, rolled back and wiped
  /// together with the session it belongs to, so it is always the current session's, and it is sent even when it has
  /// expired: Keycloak gives it the access token's short life and still accepts it at its logout endpoint.
  ///
  /// [SsoSignOut.providerLogout] fails with an [AuthError] of [AppErrorCode.authOidcLogoutIncomplete] when the
  /// provider logout failed.
  @override
  Future<SsoSignOut> signOut() async {
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
    return SsoSignOut(cleared: cleared, providerLogout: _endProviderSession(_settings.logoutHint ? idToken : null));
  }

  Future<Result<void>> _endProviderSession(String? idTokenHint) async {
    switch (await _client.endProviderSession(idTokenHint: idTokenHint)) {
      case ProviderLogoutFailed():
        _log.warn('logout: signed out of the app, but the session at the identity provider may still be active');
        return Failure(AuthError('provider logout incomplete', code: AppErrorCode.authOidcLogoutIncomplete.key));
      case ProviderSessionEnded() || NoProviderLogout() || ProviderLogoutNavigatedAway():
        return const Success(null);
    }
  }

  /// [signOut], answered once the provider logout has ended as well.
  ///
  /// The answer is [_inner]'s, except that a failed provider logout after a clean wipe is an [AuthError] with
  /// [AppErrorCode.authOidcLogoutIncomplete]. A failed wipe wins over it: data left on this device matters more.
  @override
  Future<Result<void>> logout() async {
    final signedOut = await signOut();
    final providerLogout = await signedOut.providerLogout;
    return signedOut.cleared is Failure ? signedOut.cleared : providerLogout;
  }
}
