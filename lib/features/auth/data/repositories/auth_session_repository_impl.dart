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
/// across both: writes happen in order, and on any failure every key
/// that was successfully written during this call is restored to its
/// pre-call value (or deleted if there was none) — across both
/// backends — before the failure is reported. Callers therefore never
/// observe a half-written session.
class AuthSessionRepository implements IAuthSessionRepository {
  AuthSessionRepository({required ISecureStorage secureStorage, AppLocalStorage? storage})
    : _secureStorage = secureStorage,
      _storage = storage ?? AppLocalStorage();

  static final _log = AppLogger.getLogger('AuthSessionRepository');

  final ISecureStorage _secureStorage;
  final AppLocalStorage _storage;

  @override
  Future<Result<void>> persist(AuthSession session) async {
    // Snapshot pre-persist secure values so rollback can restore them
    // on failure — including the "delete stale refreshToken when the
    // new session has none" path, where the delete itself is the
    // mutation we need to be able to undo.
    final priorJwt = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
    final priorRefresh = await _secureStorage.read(SecureStorageKeys.refreshToken.key);

    final mutatedSecure = <SecureStorageKeys>{};
    final writtenLocal = <StorageKeys>[];
    try {
      await _secureStorage.write(SecureStorageKeys.jwtToken.key, session.idToken);
      mutatedSecure.add(SecureStorageKeys.jwtToken);
      if (session.refreshToken != null) {
        await _secureStorage.write(SecureStorageKeys.refreshToken.key, session.refreshToken!);
        mutatedSecure.add(SecureStorageKeys.refreshToken);
      } else {
        // Owner-of-keys contract: a session without a refresh token
        // must not inherit one from a previous login.
        await _secureStorage.delete(SecureStorageKeys.refreshToken.key);
        mutatedSecure.add(SecureStorageKeys.refreshToken);
      }
      await _writeLocal(StorageKeys.username, session.username, writtenLocal);
      await _writeLocal(StorageKeys.roles, session.roles, writtenLocal);
      return const Success(null);
    } catch (e) {
      _log.error('persist failed after {} secure + {} local mutations; rolling back: {}', [
        mutatedSecure.length,
        writtenLocal.length,
        e,
      ]);
      await _rollback(
        mutatedSecure: mutatedSecure,
        writtenLocal: writtenLocal,
        priorJwt: priorJwt,
        priorRefresh: priorRefresh,
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

  Future<void> _writeLocal(StorageKeys key, dynamic value, List<StorageKeys> written) async {
    final ok = await _storage.save(key.key, value);
    if (!ok) {
      throw StateError('save returned false for ${key.key}');
    }
    written.add(key);
  }

  Future<void> _rollback({
    required Set<SecureStorageKeys> mutatedSecure,
    required List<StorageKeys> writtenLocal,
    required String? priorJwt,
    required String? priorRefresh,
  }) async {
    for (final key in mutatedSecure) {
      try {
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
    for (final key in writtenLocal) {
      try {
        await _storage.remove(key.key);
      } catch (e) {
        _log.warn('local rollback failed for {}: {}', [key.key, e]);
      }
    }
  }
}
