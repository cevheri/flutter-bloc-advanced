import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract interface for secure key-value storage.
///
/// Used for sensitive data like JWT tokens that should not be stored
/// in plaintext SharedPreferences.
///
/// Failure contract: every method MUST throw on platform failure so
/// that callers using Result/rollback semantics
/// (e.g. [AuthSessionRepository.persist], [SessionMigration]) can react
/// correctly. Silently swallowing errors here makes Success reports
/// meaningless. In particular, [read] does NOT collapse platform
/// failures to null — a transient read failure during a rollback
/// snapshot must not be misread as "no prior value" and lead to
/// deleting an existing token.
///
/// [read] returns null only when the key is absent. Platform / decryption
/// failures throw.
abstract interface class ISecureStorage {
  /// Read a value by [key]. Returns null only when the key is absent.
  /// Throws on platform / decryption failure so transactional callers
  /// can distinguish "missing" from "unknown".
  Future<String?> read(String key);

  /// Write a [value] for the given [key]. Throws on platform failure.
  Future<void> write(String key, String value);

  /// Delete the value for the given [key]. Throws on platform failure.
  Future<void> delete(String key);

  /// Delete all stored values. Throws on platform failure.
  Future<void> deleteAll();
}

/// Production implementation backed by [FlutterSecureStorage].
class FlutterSecureStorageAdapter implements ISecureStorage {
  static final _log = AppLogger.getLogger('FlutterSecureStorageAdapter');

  final FlutterSecureStorage _storage;

  FlutterSecureStorageAdapter({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) async {
    _log.trace('Reading secure storage key: {}', [key]);
    return await _storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) async {
    _log.trace('Writing secure storage key: {}', [key]);
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) async {
    _log.trace('Deleting secure storage key: {}', [key]);
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    _log.info('Deleting all secure storage data');
    await _storage.deleteAll();
  }
}

/// Keys for values that must be stored in the platform-backed secure
/// store (iOS Keychain, Android EncryptedSharedPreferences).
///
/// Renaming an enum value will NOT change the stored key, so user data
/// survives refactors safely. Add new entries by appending — do not
/// change existing [key] strings without a migration.
enum SecureStorageKeys {
  jwtToken('jwtToken'),
  refreshToken('refreshToken');

  const SecureStorageKeys(this.key);

  final String key;
}
