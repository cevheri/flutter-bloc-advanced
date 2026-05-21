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
///
/// Platform configuration is pinned explicitly so future package
/// upgrades or default flips cannot silently weaken the security
/// posture of stored secrets:
///
/// - **Android:** `flutter_secure_storage` ≥ 10 uses custom AES-GCM
///   ciphers by default (replacing the deprecated Jetpack Crypto
///   library). Min SDK is 23, so all targets support hardware-backed
///   key storage. No extra options are needed beyond accepting the
///   library defaults — flagged here so an audit reader does not
///   wonder whether plaintext fallback is possible.
/// - **iOS / macOS:** Keychain accessibility is pinned to
///   [KeychainAccessibility.first_unlock_this_device] so secrets are
///   readable after first unlock (e.g. background refresh) but are
///   NOT synced to iCloud Keychain across devices. This is stricter
///   than the library default of [KeychainAccessibility.first_unlock]
///   (which permits iCloud backup) — appropriate for session tokens.
class FlutterSecureStorageAdapter implements ISecureStorage {
  static final _log = AppLogger.getLogger('FlutterSecureStorageAdapter');

  static const _iosOptions = IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device);
  static const _macosOptions = MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device);

  final FlutterSecureStorage _storage;

  FlutterSecureStorageAdapter({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(iOptions: _iosOptions, mOptions: _macosOptions);

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
/// store (iOS Keychain, Android Keystore-backed ciphers).
///
/// Renaming an enum value will NOT change the stored key, so user data
/// survives refactors safely. Add new entries by appending — do not
/// change existing [key] strings without a migration.
///
/// The current strings (`'jwtToken'`, `'refreshToken'`) deliberately
/// match the legacy plaintext SharedPreferences key names so the
/// one-shot migration in [SessionMigration] can locate the source
/// data. Once analytics confirm no installs older than the migration
/// remain in the wild (target: 2 minor versions after #129 ships),
/// these can be renamed to e.g. `'secure.jwt'` / `'secure.refresh'`
/// with a one-shot migration step that copies the value forward —
/// TODO(#129-follow-up): close the legacy-name reuse loop.
enum SecureStorageKeys {
  jwtToken('jwtToken'),
  refreshToken('refreshToken');

  const SecureStorageKeys(this.key);

  final String key;
}
