import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

/// SharedPreferences-backed implementation of [IAuthSessionRepository].
///
/// SharedPreferences does not support transactions, so atomicity is
/// emulated: writes happen in order, and on any failure the keys that
/// were successfully written during this call are removed before the
/// failure is reported. The caller therefore never sees a half-written
/// session.
class AuthSessionRepository implements IAuthSessionRepository {
  AuthSessionRepository({AppLocalStorage? storage}) : _storage = storage ?? AppLocalStorage();

  static final _log = AppLogger.getLogger('AuthSessionRepository');

  final AppLocalStorage _storage;

  @override
  Future<Result<void>> persist(AuthSession session) async {
    final written = <StorageKeys>[];
    try {
      await _write(StorageKeys.jwtToken, session.idToken, written);
      if (session.refreshToken != null) {
        await _write(StorageKeys.refreshToken, session.refreshToken, written);
      }
      await _write(StorageKeys.username, session.username, written);
      await _write(StorageKeys.roles, session.roles, written);
      return const Success(null);
    } catch (e) {
      _log.error('persist failed after {} writes; rolling back: {}', [written.length, e]);
      await _rollback(written);
      return Failure(UnknownError('Session persistence failed: $e'));
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _storage.clear();
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError('Session clear failed: $e'));
    }
  }

  Future<void> _write(StorageKeys key, dynamic value, List<StorageKeys> written) async {
    final ok = await _storage.save(key.key, value);
    if (!ok) {
      throw StateError('save returned false for ${key.key}');
    }
    written.add(key);
  }

  Future<void> _rollback(List<StorageKeys> written) async {
    for (final key in written) {
      try {
        await _storage.remove(key.key);
      } catch (e) {
        _log.warn('rollback failed for {}: {}', [key.key, e]);
      }
    }
  }
}
