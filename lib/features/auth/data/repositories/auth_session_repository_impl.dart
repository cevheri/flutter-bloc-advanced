import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// Persistence-layer implementation of [IAuthSessionRepository].
///
/// Routes sensitive fields (idToken, refreshToken) to [ISecureStorage]
/// (Keychain / EncryptedSharedPreferences) and non-secret fields
/// (username, roles) to [AppLocalStorage] (SharedPreferences).
///
/// Neither backend supports transactions, so atomicity is emulated
/// across both: writes happen in order, and on any failure the keys
/// that were successfully written during this call are removed —
/// across both backends — before the failure is reported. The caller
/// therefore never sees a half-written session.
class AuthSessionRepository implements IAuthSessionRepository {
  AuthSessionRepository({required ISecureStorage secureStorage, AppLocalStorage? storage})
    : _secureStorage = secureStorage,
      _storage = storage ?? AppLocalStorage();

  static final _log = AppLogger.getLogger('AuthSessionRepository');

  final ISecureStorage _secureStorage;
  final AppLocalStorage _storage;

  @override
  Future<Result<void>> persist(AuthSession session) async {
    // Snapshot pre-persist secure values so rollback can restore them on
    // failure — including the "delete stale refreshToken when the new
    // session has none" path, where the delete itself is the mutation we
    // need to be able to undo.
    final priorJwt = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
    final priorRefresh = await _secureStorage.read(SecureStorageKeys.refreshToken.key);
    final priorCachedJwt = AppLocalStorageCached.jwtToken;

    final writtenSecure = <SecureStorageKeys>[];
    final writtenLocal = <StorageKeys>[];
    var deletedStaleRefresh = false;
    try {
      await _writeSecure(SecureStorageKeys.jwtToken, session.idToken, writtenSecure);
      // Keep the sync cache consistent with the secure store so that
      // SecurityUtils.isUserLoggedIn() returns true immediately after persist.
      AppLocalStorageCached.jwtToken = session.idToken;
      if (session.refreshToken != null) {
        await _writeSecure(SecureStorageKeys.refreshToken, session.refreshToken!, writtenSecure);
      } else {
        // Owner-of-keys contract: a session without a refresh token must
        // not inherit one from a previous login. Tracked separately so
        // rollback can restore the prior value if a later write fails.
        await _secureStorage.delete(SecureStorageKeys.refreshToken.key);
        deletedStaleRefresh = true;
      }
      await _writeLocal(StorageKeys.username, session.username, writtenLocal);
      await _writeLocal(StorageKeys.roles, session.roles, writtenLocal);
      return const Success(null);
    } catch (e) {
      _log.error('persist failed after {} secure + {} local writes; rolling back: {}', [
        writtenSecure.length,
        writtenLocal.length,
        e,
      ]);
      await _rollback(
        writtenSecure: writtenSecure,
        writtenLocal: writtenLocal,
        deletedStaleRefresh: deletedStaleRefresh,
        priorJwt: priorJwt,
        priorRefresh: priorRefresh,
        priorCachedJwt: priorCachedJwt,
      );
      return Failure(UnknownError('Session persistence failed: $e'));
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _secureStorage.delete(SecureStorageKeys.jwtToken.key);
      await _secureStorage.delete(SecureStorageKeys.refreshToken.key);
      await _storage.clear();
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError('Session clear failed: $e'));
    }
  }

  Future<void> _writeSecure(SecureStorageKeys key, String value, List<SecureStorageKeys> written) async {
    await _secureStorage.write(key.key, value);
    written.add(key);
  }

  Future<void> _writeLocal(StorageKeys key, dynamic value, List<StorageKeys> written) async {
    final ok = await _storage.save(key.key, value);
    if (!ok) {
      throw StateError('save returned false for ${key.key}');
    }
    written.add(key);
  }

  Future<void> _rollback({
    required List<SecureStorageKeys> writtenSecure,
    required List<StorageKeys> writtenLocal,
    required bool deletedStaleRefresh,
    required String? priorJwt,
    required String? priorRefresh,
    required String? priorCachedJwt,
  }) async {
    for (final key in writtenSecure) {
      try {
        // Restore the pre-persist value (or delete if there was none) so
        // that callers observing a Failure see the state as if persist
        // had never been invoked.
        final prior = switch (key) {
          SecureStorageKeys.jwtToken => priorJwt,
          SecureStorageKeys.refreshToken => priorRefresh,
        };
        if (prior == null) {
          await _secureStorage.delete(key.key);
        } else {
          await _secureStorage.write(key.key, prior);
        }
      } catch (e) {
        _log.warn('secure rollback failed for {}: {}', [key.key, e]);
      }
    }
    if (deletedStaleRefresh && priorRefresh != null) {
      try {
        await _secureStorage.write(SecureStorageKeys.refreshToken.key, priorRefresh);
      } catch (e) {
        _log.warn('refreshToken restore failed during rollback: {}', [e]);
      }
    }
    // Restore the cached JWT (set unconditionally during persist).
    AppLocalStorageCached.jwtToken = priorCachedJwt;
    for (final key in writtenLocal) {
      try {
        await _storage.remove(key.key);
      } catch (e) {
        _log.warn('local rollback failed for {}: {}', [key.key, e]);
      }
    }
  }
}
