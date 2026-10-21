import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/sso_sign_in_result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/sso_auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_auto_redirect_gate.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_session_startup.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/rotated_tokens_take_back.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';

/// [ISsoSessionStartup] over the single sign-on, the token rotation and the stored session.
///
/// [run] first completes a pending same-tab web sign-in. A rejected or cancelled one closes [_gate], so the login
/// page does not send the user straight back to the provider. Then it checks the stored access token expiry: an
/// access token that has expired is refreshed through [_rotation] when a refresh token is stored, and the session
/// ends when none is, or when the refresh is refused. A provider that cannot be reached keeps the stored session.
///
/// Only the expiry the sign-in stored is checked, never a JWT `exp`, since a provider's access token need not be a
/// JWT. Nothing else uses the client at startup, and the client runs its operations one at a time.
///
/// The refresh follows the rules of `TokenRefreshInterceptor` for the session generation ([SessionGeneration]): an
/// answer that comes after the session ended is dropped, and what it stored while the session ended is taken back. On
/// web another browser tab can end the session too: [_takeBack] records what the refresh stored, so that tab's end
/// takes it back, and when that fails [_onSessionExpired] ends the session as a 401 that a refresh cannot fix does.
class SsoSessionStartup implements ISsoSessionStartup {
  SsoSessionStartup({
    required this._auth,
    required this._rotation,
    required this._secureStorage,
    required this._sessionRepository,
    required this._gate,
    this._now = DateTime.now,
    this._takeBack,
    this._onSessionExpired,
  }) {
    if ((_takeBack == null) != (_onSessionExpired == null)) {
      throw ArgumentError('SsoSessionStartup takes a takeBack and an onSessionExpired together, or neither');
    }
  }

  static final _log = AppLogger.getLogger('SsoSessionStartup');

  final ISsoAuthRepository _auth;
  final TokenRotation _rotation;
  final ISecureStorage _secureStorage;
  final IAuthSessionRepository _sessionRepository;
  final SsoAutoRedirectGate _gate;
  final DateTime Function() _now;
  final RotatedTokensTakeBack? _takeBack;
  final void Function()? _onSessionExpired;

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
    // Noted before the first read: a wipe from here on ends it, in this tab or, heard through [_takeBack], in another.
    final generation = SessionGeneration.current;
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
    final result = await _rotation.rotate(refreshToken);
    // The wipe that ended the session cleared it, and a session signed in to since must stay: nothing is ended again.
    if (SessionGeneration.hasEnded(generation)) {
      _log.warn('startup: the session ended while the refresh was on its way, so its answer is dropped');
      return const SsoStartupSessionEnded();
    }
    switch (result) {
      case final TokensRotated rotated:
        final stored = _storedValues(rotated);
        try {
          await _store(stored);
        } catch (error) {
          _log.error('startup: the refreshed tokens could not be stored, so the session is cleared: {}', [
            error.runtimeType,
          ]);
          return _endSession();
        }
        if (SessionGeneration.hasEnded(generation)) return _takeBackStored(stored);
        // No await since the check above, so an end that another tab reports from here on finds these tokens.
        _takeBack?.record(stored, onTakeBackFailed: _onSessionExpired!);
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

  /// The fields of [rotated] that are present and not empty, in the order bearer, refresh token, ID token, expiry.
  static StoredTokens _storedValues(TokensRotated rotated) {
    final expiresAt = rotated.accessTokenExpiresAt;
    return [
      for (final (key, value) in [
        (SecureStorageKeys.jwtToken, rotated.accessToken),
        (SecureStorageKeys.refreshToken, rotated.refreshToken),
        (SecureStorageKeys.oidcIdToken, rotated.oidcIdToken),
        (SecureStorageKeys.accessTokenExpiresAt, expiresAt == null ? null : encodeAccessTokenExpiry(expiresAt)),
      ])
        if (value != null && value.isNotEmpty) (key, value),
    ];
  }

  /// Writes [stored] in its order.
  Future<void> _store(StoredTokens stored) async {
    for (final (key, value) in stored) {
      await _secureStorage.write(key.key, value);
    }
  }

  /// The session ended while [stored] was written, so the wipe may have run before a write landed: takes back what
  /// is still stored of it, and leaves a session stored since alone. A storage failure clears the session.
  Future<SsoStartupResult> _takeBackStored(StoredTokens stored) async {
    _log.warn('startup: the session ended while the refreshed tokens were stored, so they are taken back');
    try {
      for (final (key, value) in stored) {
        if (await _secureStorage.read(key.key) == value) await _secureStorage.delete(key.key);
      }
    } catch (error) {
      _log.error('startup: the refreshed tokens could not be taken back, so the session is cleared: {}', [
        error.runtimeType,
      ]);
      return _endSession();
    }
    return const SsoStartupSessionEnded();
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
