import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalStorageCached {
  static final _log = AppLogger.getLogger("AppLocalStorageCached");
  static String? jwtToken;
  static List<String>? roles;
  static String? language;
  static String? username;
  static String? theme;
  static String? brightness;

  /// Reload all cached fields from their respective backends.
  ///
  /// [jwtToken] is sourced from [ISecureStorage] only when [secureStorage]
  /// is provided. Bootstrap passes its own adapter so the JWT is restored
  /// on app launch. Intra-app callers triggered by [AppLocalStorage.save]
  /// pass nothing — they have no reason to touch the secure store, and
  /// the JWT field is kept current by [AuthSessionRepository.persist]
  /// (which writes the cache directly) and `clear` (which nulls it).
  /// This split keeps the cache layer free of a hard secure-storage
  /// dependency in test environments where the plugin is unavailable.
  static Future<void> loadCache({ISecureStorage? secureStorage}) async {
    _log.trace("Loading cache");
    if (secureStorage != null) {
      jwtToken = await secureStorage.read(SecureStorageKeys.jwtToken.key);
    }
    roles = await AppLocalStorage().read(StorageKeys.roles.key);
    language = await AppLocalStorage().read(StorageKeys.language.key) ?? "en";
    username = await AppLocalStorage().read(StorageKeys.username.key);
    theme = await AppLocalStorage().read(StorageKeys.theme.key) ?? "classic";
    brightness = await AppLocalStorage().read(StorageKeys.brightness.key) ?? "light";
    _log.trace("Loaded cache with username:{}, roles:{}, language:{}, jwt-present:{}, theme:{}, brightness:{}", [
      username,
      roles,
      language,
      jwtToken != null,
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
