import 'dart:async';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/startup_storage_time_limit.dart';

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
/// Bootstrap waits for it before runApp, so it gives up after [timeLimit]
/// ([StartupStorageTimeLimit.defaultDuration] unless given another): it
/// logs an error and returns, the app starts without it, and the next
/// launch runs it again. A migration that gave up starts no write or
/// remove when secure storage answers later, because the user may have
/// signed in or out by then and a late write of the legacy token would
/// replace that session. A write it sent before it gave up cannot be
/// called back and may still land, also after the user has signed in;
/// the plaintext copy then stays until a later launch finds a token in
/// secure storage and removes the copy. The plaintext copy is removed
/// only after a read of secure storage has found a token there.
///
/// Top-level function — there is no state, no polymorphism, no
/// related helpers worth namespacing. The previous `SessionMigration`
/// class wrapper carried zero information beyond what the function
/// name already conveys.
Future<void> runSessionMigration({
  required ISecureStorage secureStorage,
  required AppLocalStorage localStorage,
  Duration timeLimit = StartupStorageTimeLimit.defaultDuration,
}) async {
  var gaveUp = false;
  Future<void> migrate() async {
    for (final legacyKey in _legacyKeys) {
      if (gaveUp) return;
      await _migrateOne(legacyKey, secureStorage, localStorage, gaveUp: () => gaveUp);
    }
  }

  try {
    await StartupStorageTimeLimit(migrate(), duration: timeLimit).result;
  } on TimeoutException {
    gaveUp = true;
    _log.error(
      'Secure storage did not answer within {} ms; the app starts without the migration, the next launch retries',
      [timeLimit.inMilliseconds],
    );
  }
}

Future<void> _migrateOne(
  String legacyKey,
  ISecureStorage secureStorage,
  AppLocalStorage localStorage, {
  required bool Function() gaveUp,
}) async {
  try {
    final existing = await secureStorage.read(legacyKey);
    // AppLocalStorage.read returns Future<dynamic>; narrow to String
    // up front so the rest of the function operates on a concrete
    // type and a future regression can't quietly send a non-String
    // down to secure-storage write / verify.
    final legacyRaw = await localStorage.read(legacyKey);
    final String? legacy = legacyRaw is String ? legacyRaw : null;
    final hasLegacyPlaintext = legacy != null && legacy.isNotEmpty;

    if (gaveUp()) {
      _log.warn('Secure storage answered after the migration gave up; {} is left for the next launch', [legacyKey]);
      return;
    }

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
    if (gaveUp()) {
      _log.warn(
        'Secure storage answered the {} write after the migration gave up; its plaintext copy is left for the next launch',
        [legacyKey],
      );
      return;
    }

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
