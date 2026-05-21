import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

final _log = AppLogger.getLogger('SessionMigration');

/// Legacy SharedPreferences keys to migrate into [ISecureStorage].
/// Sourced from [SecureStorageKeys] so the canonical token-key
/// strings stay in lockstep — if a key string ever changes, this
/// list moves with it automatically.
final _legacyKeys = <String>[SecureStorageKeys.jwtToken.key, SecureStorageKeys.refreshToken.key];

/// One-shot migration from plaintext SharedPreferences to SecureStorage.
///
/// Runs at bootstrap before [AppLocalStorageCached.loadCache] so the
/// cache sees the post-migration state. Idempotent: any value already
/// present in [ISecureStorage] is left alone. Best-effort: a failure
/// logs a warning and returns; worst case the user re-authenticates
/// on the next launch.
///
/// Top-level function — there is no state, no polymorphism, no
/// related helpers worth namespacing. The previous `SessionMigration`
/// class wrapper carried zero information beyond what the function
/// name already conveys.
Future<void> runSessionMigration({required ISecureStorage secureStorage, required AppLocalStorage localStorage}) async {
  for (final legacyKey in _legacyKeys) {
    await _migrateOne(legacyKey, secureStorage, localStorage);
  }
}

Future<void> _migrateOne(String legacyKey, ISecureStorage secureStorage, AppLocalStorage localStorage) async {
  try {
    final existing = await secureStorage.read(legacyKey);
    // AppLocalStorage.read returns Future<dynamic>; narrow to String
    // up front so the rest of the function operates on a concrete
    // type and a future regression can't quietly send a non-String
    // down to secure-storage write / verify.
    final legacyRaw = await localStorage.read(legacyKey);
    final String? legacy = legacyRaw is String ? legacyRaw : null;
    final hasLegacyPlaintext = legacy != null && legacy.isNotEmpty;

    if (existing != null && existing.isNotEmpty) {
      // Already migrated. But if a plaintext copy is still lingering
      // in SharedPreferences — a previous migration may have left it
      // behind, or the migration was interrupted between write and
      // remove — clean it up now. Best-effort: the token is safe in
      // secure storage, so a remove failure just delays cleanup
      // until the next launch.
      if (hasLegacyPlaintext) {
        try {
          final removed = await localStorage.remove(legacyKey);
          if (removed) {
            _log.info('Cleaned up lingering plaintext {} after prior migration', [legacyKey]);
          } else {
            _log.warn('Lingering plaintext {} remove returned false; will retry next launch', [legacyKey]);
          }
        } catch (e) {
          _log.warn('Lingering plaintext {} cleanup failed: {}', [legacyKey, e]);
        }
      }
      return;
    }

    if (!hasLegacyPlaintext) return;

    await secureStorage.write(legacyKey, legacy);

    // Verify the write actually landed before deleting the legacy copy.
    // The adapter throws on platform errors, but defense-in-depth: if a
    // future custom adapter quietly drops a write we must not orphan the
    // token by removing the only remaining copy.
    final verify = await secureStorage.read(legacyKey);
    if (verify != legacy) {
      _log.warn('Migration verify mismatch for {}; legacy key retained', [legacyKey]);
      return;
    }

    final removed = await localStorage.remove(legacyKey);
    if (!removed) {
      // The token IS now in secure storage (write+verify above), so the
      // user is not stranded — but a leftover plaintext copy in
      // SharedPreferences is exactly what this migration is meant to
      // eliminate. Surface it so operators can act.
      _log.warn(
        'Migrated {} to SecureStorage but legacy SharedPreferences remove returned false; plaintext value may persist',
        [legacyKey],
      );
      return;
    }
    _log.info('Migrated {} from SharedPreferences to SecureStorage', [legacyKey]);
  } catch (e) {
    _log.warn('Migration failed for {}: {}', [legacyKey, e]);
  }
}
