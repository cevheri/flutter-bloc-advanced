import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalStorageCached {
  static final _log = AppLogger.getLogger("AppLocalStorageCached");
  static late String? jwtToken;
  static late List<String>? roles;
  static late String? language;
  static late String? username;
  static late String? theme;
  static late String? brightness;

  /// Reload the local-storage-backed fields from [AppLocalStorage].
  ///
  /// [jwtToken] is intentionally NOT reloaded here because it lives in
  /// secure storage (Keychain / EncryptedSharedPreferences). It is
  /// updated directly by [AuthSessionRepository.persist] and cleared by
  /// [AuthSessionRepository.clear] or [AppLocalStorage.clear]. Calling
  /// the secure storage plugin synchronously on every [AppLocalStorage.save]
  /// would be both slow and fragile in test environments where the plugin
  /// is unavailable.
  static Future<void> loadCache() async {
    _log.trace("Loading cache");
    roles = await AppLocalStorage().read(StorageKeys.roles.key);
    language = await AppLocalStorage().read(StorageKeys.language.key) ?? "en";
    username = await AppLocalStorage().read(StorageKeys.username.key);
    theme = await AppLocalStorage().read(StorageKeys.theme.key) ?? "classic";
    brightness = await AppLocalStorage().read(StorageKeys.brightness.key) ?? "light";
    _log.trace("Loaded cache with username:{}, roles:{}, language:{}, jwtToken:{}, theme:{}, brightness:{}", [
      username,
      roles,
      language,
      jwtToken,
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
enum StorageKeys {
  roles('roles'),
  language('language'),
  username('username'),
  theme('theme'),
  brightness('brightness');

  const StorageKeys(this.key);

  final String key;
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
  /// Returns false if value type is not supported or an error occurs.
  Future<bool> save(String key, dynamic value) async {
    _log.trace("Saving data to local storage {} {}", [key, value]);
    final prefs = await _prefs;
    try {
      if (value is String) {
        prefs.setString(key, value);
      } else if (value is int) {
        prefs.setInt(key, value);
      } else if (value is double) {
        prefs.setDouble(key, value);
      } else if (value is bool) {
        prefs.setBool(key, value);
      } else if (value is List<String>) {
        prefs.setStringList(key, value);
      } else {
        throw Exception("Unsupported value type");
      }

      await AppLocalStorageCached.loadCache();
      _log.trace("Saved data to local storage {} {}", [key, value]);
      return true;
    } catch (e) {
      _log.error("Error saving data to local storage: {}, {}", [key, e]);
      return false;
    }
  }

  Future<dynamic> read(String key) async {
    _log.trace("Reading data from local storage");
    final prefs = await _prefs;
    return prefs.get(key);
  }

  Future<bool> remove(String key) async {
    _log.trace("Removing data from local storage");
    try {
      final prefs = await _prefs;
      prefs.remove(key);
      await AppLocalStorageCached.loadCache();
      _log.trace("Removed data from local storage {}", [key]);
      return true;
    } catch (e) {
      _log.error("Error removing data from local storage: {}, {}", [key, e]);
      return false;
    }
  }

  Future<void> clear() async {
    _log.info("Clearing all data from local storage");
    final prefs = await _prefs;
    prefs.clear();
    // Also clear the secure-storage cache entry so that SecurityUtils
    // reflects the cleared state synchronously.
    AppLocalStorageCached.jwtToken = null;
    await AppLocalStorageCached.loadCache();
    _log.info("Cleared all data from local storage");
  }
}
