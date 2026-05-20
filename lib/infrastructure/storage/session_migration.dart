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

  static const _legacyKeys = <String>['jwtToken', 'refreshToken'];

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
      await localStorage.remove(legacyKey);
      _log.info('Migrated {} from SharedPreferences to SecureStorage', [legacyKey]);
    } catch (e) {
      _log.warn('Migration failed for {}: {}', [legacyKey, e]);
    }
  }
}
