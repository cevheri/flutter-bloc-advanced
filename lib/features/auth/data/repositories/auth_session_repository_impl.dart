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
    final writtenSecure = <SecureStorageKeys>[];
    final writtenLocal = <StorageKeys>[];
    try {
      await _writeSecure(SecureStorageKeys.jwtToken, session.idToken, writtenSecure);
      // Keep the sync cache consistent with the secure store so that
      // SecurityUtils.isUserLoggedIn() returns true immediately after persist.
      AppLocalStorageCached.jwtToken = session.idToken;
      if (session.refreshToken != null) {
        await _writeSecure(SecureStorageKeys.refreshToken, session.refreshToken!, writtenSecure);
      } else {
        // Owner-of-keys contract: a session without a refresh token must
        // not inherit one from a previous login. Best-effort removal.
        await _secureStorage.delete(SecureStorageKeys.refreshToken.key);
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
      await _rollback(writtenSecure, writtenLocal);
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

  Future<void> _rollback(List<SecureStorageKeys> writtenSecure, List<StorageKeys> writtenLocal) async {
    for (final key in writtenSecure) {
      try {
        await _secureStorage.delete(key.key);
        if (key == SecureStorageKeys.jwtToken) {
          // Keep the sync cache consistent with the rolled-back secure store.
          AppLocalStorageCached.jwtToken = null;
        }
      } catch (e) {
        _log.warn('secure rollback failed for {}: {}', [key.key, e]);
      }
    }
    for (final key in writtenLocal) {
      try {
        await _storage.remove(key.key);
      } catch (e) {
        _log.warn('local rollback failed for {}: {}', [key.key, e]);
      }
    }
  }
}
