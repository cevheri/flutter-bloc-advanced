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
    final mutatedSecure = <SecureStorageKeys>{};
    final mutatedLocal = <StorageKeys>{};
    // Snapshot pre-persist values on BOTH backends so rollback restores
    // them — including the "delete stale refreshToken when the new
    // session has none" path, where the delete itself is the mutation
    // we need to be able to undo. The snapshot itself must live inside
    // the try block: ISecureStorage.read can throw on platform /
    // decryption failure, and the contract is that persist always
    // returns a Result — never propagates a raw exception.
    String? priorJwt;
    String? priorRefresh;
    dynamic priorUsername;
    dynamic priorRoles;
    try {
      priorJwt = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
      priorRefresh = await _secureStorage.read(SecureStorageKeys.refreshToken.key);
      priorUsername = await _storage.read(StorageKeys.username.key);
      priorRoles = await _storage.read(StorageKeys.roles.key);

      await _secureStorage.write(SecureStorageKeys.jwtToken.key, session.idToken);
      mutatedSecure.add(SecureStorageKeys.jwtToken);
      // Owner-of-keys contract: a session without a refresh token must
      // not inherit one from a previous login. Treat null AND empty
      // string equivalently — TokenRefreshInterceptor reads
      // `refreshToken.isEmpty` as "absent", so persisting an empty
      // string here would leave the key present but unusable.
      final hasRefresh = session.refreshToken != null && session.refreshToken!.isNotEmpty;
      if (hasRefresh) {
        await _secureStorage.write(SecureStorageKeys.refreshToken.key, session.refreshToken!);
      } else {
        await _secureStorage.delete(SecureStorageKeys.refreshToken.key);
      }
      mutatedSecure.add(SecureStorageKeys.refreshToken);
      await _writeLocal(StorageKeys.username, session.username, mutatedLocal);
      await _writeLocal(StorageKeys.roles, session.roles, mutatedLocal);
      _log.info('persist: session written ({} secure + {} local)', [mutatedSecure.length, mutatedLocal.length]);
      return const Success(null);
    } catch (e) {
      _log.error('persist failed after {} secure + {} local mutations; rolling back: {}', [
        mutatedSecure.length,
        mutatedLocal.length,
        e,
      ]);
      await _rollback(
        mutatedSecure: mutatedSecure,
        mutatedLocal: mutatedLocal,
        priorJwt: priorJwt,
        priorRefresh: priorRefresh,
        priorUsername: priorUsername,
        priorRoles: priorRoles,
      );
      return Failure(UnknownError('Session persistence failed: $e'));
    }
  }

  @override
  Future<Result<void>> clear() async {
    // Best-effort across BOTH backends: a throw on the first secure
    // delete must not skip the second key or the local clear. Any
    // leftover token would let AuthInterceptor re-attach it on the
    // next request and silently defeat a clear/logout.
    final errors = <String>[];
    try {
      await _secureStorage.delete(SecureStorageKeys.jwtToken.key);
    } catch (e) {
      errors.add('jwt: $e');
    }
    try {
      await _secureStorage.delete(SecureStorageKeys.refreshToken.key);
    } catch (e) {
      errors.add('refresh: $e');
    }
    try {
      await _storage.clear();
    } catch (e) {
      errors.add('local: $e');
    }
    if (errors.isNotEmpty) {
      final msg = errors.join('; ');
      _log.error('clear: partial failures: {}', [msg]);
      return Failure(UnknownError('Session clear failed: $msg'));
    }
    _log.info('clear: session wiped from both backends');
    return const Success(null);
  }

  Future<void> _writeLocal(StorageKeys key, dynamic value, Set<StorageKeys> mutated) async {
    final ok = await _storage.save(key.key, value);
    if (!ok) {
      throw StateError('save returned false for ${key.key}');
    }
    mutated.add(key);
  }

  Future<void> _rollback({
    required Set<SecureStorageKeys> mutatedSecure,
    required Set<StorageKeys> mutatedLocal,
    required String? priorJwt,
    required String? priorRefresh,
    required dynamic priorUsername,
    required dynamic priorRoles,
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
    for (final key in mutatedLocal) {
      try {
        // Compile-time exhaustive — adding a new StorageKeys variant
        // here without snapshotting its prior value will surface as
        // a missing case at build time, not as a silent rollback-to-
        // null (== delete). Persist mutates only the keys listed
        // below; any new local field this repository persists must
        // also extend the snapshot/restore signature.
        final prior = switch (key) {
          StorageKeys.username => priorUsername,
          StorageKeys.roles => priorRoles,
          StorageKeys.language => null,
          StorageKeys.theme => null,
          StorageKeys.brightness => null,
        };
        // AppLocalStorage.save/remove can refuse a mutation by returning
        // false without throwing. Honor that signal so a rollback that
        // silently no-ops doesn't leave storage in a partially-mutated
        // state — symmetric with how _writeLocal treats save == false.
        final ok = prior == null ? await _storage.remove(key.key) : await _storage.save(key.key, prior);
        if (!ok) {
          _log.warn('local rollback refused for {} (storage returned false)', [key.key]);
        }
      } catch (e) {
        _log.warn('local rollback failed for {}: {}', [key.key, e]);
      }
    }
  }
}
