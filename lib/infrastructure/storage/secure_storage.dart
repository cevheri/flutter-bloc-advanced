import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract interface for secure key-value storage.
///
/// Used for sensitive data like JWT tokens that should not be stored
/// in plaintext SharedPreferences.
///
/// Failure contract: every method MUST throw on platform failure so
/// that callers using Result/rollback semantics — the session-persist
/// repository and the session-migration runner — can react correctly.
/// Silently swallowing errors here makes Success reports meaningless.
/// In particular, [read] does NOT collapse platform failures to null
/// — a transient read failure during a rollback snapshot must not be
/// misread as "no prior value" and lead to deleting an existing token.
///
/// [read] returns null only when the key is absent. Platform / decryption
/// failures throw.
///
/// Android exception: [FlutterSecureStorageAdapter] keeps the plugin default
/// `resetOnError: true`. When an entry can no longer be decrypted (for
/// example after a backup restore without its Keystore key), the plugin
/// deletes it and [read] returns null, so the caller sees an absent key.
/// With `resetOnError: false`, a lost Keystore key would leave the whole
/// store unusable, including writes, which blocks sign-in.
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
/// - **Android:** `flutter_secure_storage` ≥ 11 encrypts with AES-GCM
///   under an RSA-OAEP wrapped Android Keystore key. The legacy
///   RSA-PKCS1 / AES-CBC ciphers and the Jetpack EncryptedSharedPreferences
///   backend were removed in 11.0.0; data written by 10.x is read as-is.
///   The plugin's min SDK is 24, so all targets support hardware-backed
///   key storage. No extra options are needed beyond accepting the
///   library defaults — flagged here so an audit reader does not
///   wonder whether plaintext fallback is possible.
/// - **iOS:** Keychain accessibility is pinned to
///   [KeychainAccessibility.first_unlock_this_device]: secrets are
///   readable after the first unlock until a restart, so a background
///   refresh can read them while the device is locked, and they never
///   move to another device through a backup or iCloud Keychain. The
///   library default, [KeychainAccessibility.unlocked], reads only while
///   the device is unlocked and lets an item move to a new device in an
///   encrypted backup; keeping session tokens on this device is the part
///   that matters for them.
/// - **macOS:** `usesDataProtectionKeychain: false` keeps secrets in the
///   login keychain (the file-based keychain). The data protection
///   keychain needs a `keychain-access-groups` entitlement authorized by
///   a provisioning profile, and the template's build is signed ad hoc
///   with no team, so storing the session there fails with
///   errSecMissingEntitlement (-34018) and sign-in would roll back.
///   No accessibility level is set. Apple applies kSecAttrAccessible on
///   macOS only when kSecUseDataProtectionKeychain or
///   kSecAttrSynchronizable is true, and with a level set,
///   flutter_secure_storage_darwin retries a lookup that found nothing
///   with a kSecAttrAccessControl query, which macOS sends to the data
///   protection keychain only.
///   A login keychain item is protected by an access control list that
///   names the app that created it. An ad-hoc signature names the app by
///   its code hash, which a rebuild changes, so after a rebuild macOS
///   asks for the login keychain password the first time the app reads
///   the stored session.
///   A fork with an Apple Developer team and a provisioning profile can
///   move to the data protection keychain, which Apple recommends
///   (TN3137): add `keychain-access-groups` to both
///   `macos/Runner/*.entitlements` files, then set
///   `usesDataProtectionKeychain: true` and the same `accessibility` as
///   on iOS. The data protection keychain does not see login keychain
///   items, so users sign in once more.
class FlutterSecureStorageAdapter implements ISecureStorage {
  static final _log = AppLogger.getLogger('FlutterSecureStorageAdapter');

  static const _iosOptions = IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device);
  static const _macosOptions = MacOsOptions(accessibility: null, usesDataProtectionKeychain: false);

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
/// one-shot `runSessionMigration()` can locate the source data
/// (see `session_migration.dart`). Once analytics confirm no installs
/// older than the migration
/// remain in the wild (target: 2 minor versions after #129 ships),
/// these can be renamed to e.g. `'secure.jwt'` / `'secure.refresh'`
/// with a one-shot migration step that copies the value forward —
/// TODO(#129-follow-up): close the legacy-name reuse loop.
///
/// [oidcIdToken] and [accessTokenExpiresAt] are used only in an `oidc`
/// build. The OIDC ID token has its own name so it cannot be confused
/// with [jwtToken], which holds the bearer under the legacy name. The
/// expiry is stored with [encodeAccessTokenExpiry] and read with
/// [readAccessTokenExpiry].
enum SecureStorageKeys {
  jwtToken('jwtToken'),
  refreshToken('refreshToken'),
  oidcIdToken('oidcIdToken'),
  accessTokenExpiresAt('accessTokenExpiresAt');

  const SecureStorageKeys(this.key);

  final String key;
}

/// The stored form of an access token expiry: milliseconds since the epoch in UTC, as a decimal string.
String encodeAccessTokenExpiry(DateTime expiresAt) => expiresAt.toUtc().millisecondsSinceEpoch.toString();

/// Reads an expiry stored by [encodeAccessTokenExpiry] as a UTC [DateTime]; null when none is stored.
///
/// Throws [FormatException] when [stored] is not an integer.
DateTime? readAccessTokenExpiry(String? stored) {
  if (stored == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(int.parse(stored), isUtc: true);
}
