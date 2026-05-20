import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// One-shot migration from plaintext SharedPreferences to SecureStorage.
///
/// Runs at bootstrap before [AppLocalStorageCached.loadCache] so the
/// cache sees the post-migration state. Idempotent: any value already
/// present in [ISecureStorage] is left alone. Best-effort: a failure
/// logs a warning and returns; worst case the user re-authenticates
/// on the next launch.
class SessionMigration {
  static final _log = AppLogger.getLogger('SessionMigration');

  /// Legacy SharedPreferences keys to migrate into [ISecureStorage].
  /// Sourced from [SecureStorageKeys] so the canonical token-key
  /// strings stay in lockstep — if a key string ever changes, this
  /// list moves with it automatically.
  static final _legacyKeys = <String>[SecureStorageKeys.jwtToken.key, SecureStorageKeys.refreshToken.key];

  static Future<void> run({required ISecureStorage secureStorage, required AppLocalStorage localStorage}) async {
    for (final legacyKey in _legacyKeys) {
      await _migrateOne(legacyKey, secureStorage, localStorage);
    }
  }

  static Future<void> _migrateOne(String legacyKey, ISecureStorage secureStorage, AppLocalStorage localStorage) async {
    try {
      final existing = await secureStorage.read(legacyKey);
      if (existing != null && existing.isNotEmpty) return;

      final legacy = await localStorage.read(legacyKey);
      if (legacy is! String || legacy.isEmpty) return;

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
}
