import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory cache for fields that are read synchronously across the app.
///
/// The JWT is intentionally NOT cached here: it lives in `ISecureStorage`
/// and is read on demand by `AuthInterceptor` (per-request) and by
/// `SessionCubit.restore` (per app launch). `SecurityUtils` itself is
/// pure — it takes the token as an argument and does no I/O.
///
/// The other fields legitimately live in SharedPreferences and a sync
/// read is cheap and correct.
class AppLocalStorageCached {
  static final _log = AppLogger.getLogger("AppLocalStorageCached");
  static List<String>? roles;
  static String? language;
  static String? username;
  static String? theme;
  static String? brightness;

  static Future<void> loadCache() async {
    _log.trace("Loading cache");
    roles = await AppLocalStorage().read(StorageKeys.roles.key);
    language = await AppLocalStorage().read(StorageKeys.language.key) ?? "en";
    username = await AppLocalStorage().read(StorageKeys.username.key);
    theme = await AppLocalStorage().read(StorageKeys.theme.key) ?? "classic";
    brightness = await AppLocalStorage().read(StorageKeys.brightness.key) ?? "light";
    _log.trace("Loaded cache with username:{}, roles:{}, language:{}, theme:{}, brightness:{}", [
      username,
      roles,
      language,
      theme,
      brightness,
    ]);
  }
}

/// LocalStorage predefined keys.
///
/// Each enum value carries an explicit [key] string used as the
/// SharedPreferences key. Renaming an enum value will NOT change the
/// stored key, so user data survives refactors safely. Add new entries
/// by appending — do not change existing [key] strings without a
/// migration.
///
/// Each value also has a [scope], which decides whether ending a session removes it.
enum StorageKeys {
  roles('roles'),
  language('language'),
  username('username'),
  theme('theme'),
  brightness('brightness'),
  sidebarCollapsed('sidebarCollapsed'),

  /// The JWT in plaintext, where releases before the move to secure storage kept it. `runSessionMigration` moves it
  /// to secure storage, and it stays here only when the migration cannot remove it.
  legacyJwtToken('jwtToken'),

  /// The refresh token in plaintext, left behind like [legacyJwtToken].
  legacyRefreshToken('refreshToken');

  const StorageKeys(this.key);

  final String key;

  /// Whether this key belongs to the signed-in user or to the device. The switch is exhaustive on purpose: a new key
  /// does not compile until it is classified, so a logout neither leaves it for the next user nor drops a preference.
  StorageScope get scope => switch (this) {
    StorageKeys.roles => StorageScope.session,
    StorageKeys.language => StorageScope.device,
    StorageKeys.username => StorageScope.session,
    StorageKeys.theme => StorageScope.device,
    StorageKeys.brightness => StorageScope.device,
    StorageKeys.sidebarCollapsed => StorageScope.device,
    StorageKeys.legacyJwtToken => StorageScope.session,
    StorageKeys.legacyRefreshToken => StorageScope.session,
  };
}

/// Whom a [StorageKeys] value belongs to.
enum StorageScope {
  /// The signed-in user: ending the session removes the value, so the next user of the device never sees it.
  session,

  /// The device, like the chosen language and theme: the value outlives every session.
  device,
}

/// Application Local Storage
///
/// Uses SharedPreferences to store data locally.
class AppLocalStorage {
  static final _log = AppLogger.getLogger("AppLocalStorage");
  static final AppLocalStorage _instance = AppLocalStorage._internal();

  AppLocalStorage._internal() {
    _log.trace("Creating AppLocalStorage instance");
  }

  factory AppLocalStorage() => _instance;

  SharedPreferences? _prefsInstance;

  @visibleForTesting
  void setPreferencesInstance(SharedPreferences prefs) {
    _prefsInstance = prefs;
  }

  Future<SharedPreferences> get _prefs async => _prefsInstance ??= await SharedPreferences.getInstance();

  /// Save data to local storage.
  ///
  /// Supported value types: String, int, double, bool, `List<String>`.
  /// Returns false if the value type is unsupported, the underlying
  /// SharedPreferences write reports failure, or an error is thrown.
  /// This boolean is the contract that [AuthSessionRepository._writeLocal]
  /// relies on for cross-backend rollback — silent success here breaks
  /// atomicity, so each platform call is awaited and its result honored.
  Future<bool> save(String key, dynamic value) async {
    _log.trace("Saving data to local storage {} {}", [key, value]);
    final prefs = await _prefs;
    final bool ok;
    try {
      if (value is String) {
        ok = await prefs.setString(key, value);
      } else if (value is int) {
        ok = await prefs.setInt(key, value);
      } else if (value is double) {
        ok = await prefs.setDouble(key, value);
      } else if (value is bool) {
        ok = await prefs.setBool(key, value);
      } else if (value is List<String>) {
        ok = await prefs.setStringList(key, value);
      } else {
        throw Exception("Unsupported value type");
      }
    } catch (e) {
      _log.error("Error saving data to local storage: {}, {}", [key, e]);
      return false;
    }
    if (!ok) {
      _log.error("SharedPreferences refused write for key {}", [key]);
      return false;
    }
    // Refresh the in-memory cache. A failure here means the cache
    // is stale, NOT that the write failed — the write already landed
    // above. Returning false from this path would falsely flag a
    // successful save as a failure and trigger the cross-backend
    // rollback in AuthSessionRepository._writeLocal, undoing a
    // legitimate login over a transient SharedPreferences read error.
    try {
      await AppLocalStorageCached.loadCache();
    } catch (e) {
      _log.warn("Post-save cache refresh failed for {} — cache may be stale: {}", [key, e]);
    }
    _log.trace("Saved data to local storage {} {}", [key, value]);
    return true;
  }

  Future<dynamic> read(String key) async {
    _log.trace("Reading data from local storage");
    final prefs = await _prefs;
    return prefs.get(key);
  }

  Future<bool> remove(String key) async {
    _log.trace("Removing data from local storage");
    final bool ok;
    try {
      final prefs = await _prefs;
      ok = await prefs.remove(key);
    } catch (e) {
      _log.error("Error removing data from local storage: {}, {}", [key, e]);
      return false;
    }
    if (!ok) {
      _log.error("SharedPreferences refused remove for key {}", [key]);
      return false;
    }
    // Same cache-refresh-failure invariant as [save]: a failure here
    // does not mean the remove failed (it landed above) — only that
    // the cache is now stale. Treating it as a failure would block
    // logout from an unrelated transient error.
    try {
      await AppLocalStorageCached.loadCache();
    } catch (e) {
      _log.warn("Post-remove cache refresh failed for {} — cache may be stale: {}", [key, e]);
    }
    _log.trace("Removed data from local storage {}", [key]);
    return true;
  }

  Future<void> clear() async {
    _log.info("Clearing all data from local storage");
    final prefs = await _prefs;
    final ok = await prefs.clear();
    if (!ok) {
      // Symmetric with [save] / [remove]: a refused mutation surfaces to
      // the caller as an exception instead of logging "Cleared all data"
      // over stale state. clear() wipes every preference, so only test
      // setup calls it; ending a session removes the session keys
      // through [remove] instead.
      _log.error("SharedPreferences clear returned false");
      throw StateError('SharedPreferences clear returned false');
    }
    // Same cache-refresh-failure invariant as [save] / [remove]: the
    // clear() mutation already landed above. A loadCache failure
    // means the in-memory cache is stale, NOT that the clear failed,
    // so it is logged and the wipe still counts as done.
    try {
      await AppLocalStorageCached.loadCache();
    } catch (e) {
      _log.warn("Post-clear cache refresh failed — cache may be stale: {}", [e]);
    }
    _log.info("Cleared all data from local storage");
  }
}
