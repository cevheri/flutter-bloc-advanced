import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/sso_sign_in_result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/sso_auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_auto_redirect_gate.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_session_startup.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// [ISsoSessionStartup] over the single sign-on, the token rotation and the stored session.
///
/// [run] first completes a pending same-tab web sign-in. A rejected or cancelled one closes [_gate], so the login
/// page does not send the user straight back to the provider. Then it checks the stored access token expiry: an
/// access token that has expired is refreshed through [_rotation] when a refresh token is stored, and the session
/// ends when none is, or when the refresh is refused. A provider that cannot be reached keeps the stored session.
///
/// Only the expiry the sign-in stored is checked, never a JWT `exp`, since a provider's access token need not be a
/// JWT. Nothing else uses the client at startup, and the client runs its operations one at a time.
class SsoSessionStartup implements ISsoSessionStartup {
  SsoSessionStartup({
    required this._auth,
    required this._rotation,
    required this._secureStorage,
    required this._sessionRepository,
    required this._gate,
    this._now = DateTime.now,
  });

  static final _log = AppLogger.getLogger('SsoSessionStartup');

  final ISsoAuthRepository _auth;
  final TokenRotation _rotation;
  final ISecureStorage _secureStorage;
  final IAuthSessionRepository _sessionRepository;
  final SsoAutoRedirectGate _gate;
  final DateTime Function() _now;

  @override
  Future<SsoStartupResult> run() async {
    final SsoSignInResult? pending;
    try {
      pending = await _auth.completePendingSignIn();
    } catch (error) {
      // Only the type: a corrupt transaction store's exception may carry what it holds.
      _log.error('startup: the pending web sign-in could not be completed: {}', [error.runtimeType]);
      _gate.close();
      return const SsoStartupSignInFailed(AppErrorCode.authOidcFailed);
    }
    switch (pending) {
      case SsoSignInSucceeded(:final roles):
        return SsoStartupSignedIn(roles: roles);
      case SsoSignInRejected(:final errorCode):
        _gate.close();
        return SsoStartupSignInFailed(errorCode);
      case SsoSignInCancelled():
        // The tab came back without an answer, such as with Back: no automatic redirect may take it there again.
        _gate.close();
      case SsoSignInNavigatedAway():
        _gate.close();
        throw StateError('A pending web sign-in completed by leaving the page');
      case null:
        break;
    }
    return _refreshExpiredSession();
  }

  @override
  void giveUp() => _gate.close();

  /// Refreshes the stored session when its access token has expired, see [run].
  Future<SsoStartupResult> _refreshExpiredSession() async {
    final DateTime? expiresAt;
    final String? refreshToken;
    try {
      expiresAt = readAccessTokenExpiry(await _secureStorage.read(SecureStorageKeys.accessTokenExpiresAt.key));
      if (expiresAt == null || expiresAt.isAfter(_now())) return const SsoStartupUseStoredSession();
      refreshToken = await _secureStorage.read(SecureStorageKeys.refreshToken.key);
    } catch (error) {
      // Only the type: the FormatException of a malformed expiry repeats the stored value.
      _log.error('startup: the stored session could not be read, so it is cleared: {}', [error.runtimeType]);
      return _endSession();
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      _log.info('startup: the access token has expired and no refresh token is stored, so the session ends');
      return _endSession();
    }
    switch (await _rotation.rotate(refreshToken)) {
      case final TokensRotated rotated:
        try {
          await _store(rotated);
        } catch (error) {
          _log.error('startup: the refreshed tokens could not be stored, so the session is cleared: {}', [
            error.runtimeType,
          ]);
          return _endSession();
        }
        _log.info('startup: the expired access token was refreshed');
        return const SsoStartupUseStoredSession();
      case RotationRefused():
        _log.info('startup: the identity provider refused the refresh, so the session ends');
        return _endSession();
      case RotationUnavailable():
        _log.warn('startup: the identity provider could not be reached to refresh, so the stored session is kept');
        return const SsoStartupUseStoredSession();
    }
  }

  /// Writes the fields of [rotated] that are present and not empty, in the order bearer, refresh token, ID token,
  /// expiry.
  Future<void> _store(TokensRotated rotated) async {
    final expiresAt = rotated.accessTokenExpiresAt;
    for (final (key, value) in [
      (SecureStorageKeys.jwtToken, rotated.accessToken),
      (SecureStorageKeys.refreshToken, rotated.refreshToken),
      (SecureStorageKeys.oidcIdToken, rotated.oidcIdToken),
      (SecureStorageKeys.accessTokenExpiresAt, expiresAt == null ? null : encodeAccessTokenExpiry(expiresAt)),
    ]) {
      if (value != null && value.isNotEmpty) await _secureStorage.write(key.key, value);
    }
  }

  Future<SsoStartupResult> _endSession() async {
    switch (await _sessionRepository.clear()) {
      case Success():
        break;
      case Failure(:final error):
        // Only the type: AuthSessionRepository.clear has logged the storage errors themselves.
        _log.error('startup: the stored session was not fully cleared: {}', [error.runtimeType]);
    }
    return const SsoStartupSessionEnded();
  }
}
