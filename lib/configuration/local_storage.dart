// Storage wrapper for shared preferences and get storage in Application (with strategy pattern)
// This file contains the implementation of the local storage for the application.
// It uses shared preferences and get storage to store data locally.
// It also contains the implementation of the cache for the application.

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageStrategy {
  Future<bool> save(String key, dynamic value);

  Future<dynamic> read(String key);

  Future<bool> remove(String key);

  Future<void> clear();
}

class AppLocalStorageCached {
  static final _log = AppLogger.getLogger("AppLocalStorageCached");
  static late String? jwtToken;
  static late List<String>? roles;
  static late String? language;
  static late String? username;
  static late String? theme;
  static late String? brightness;

  static Future<void> loadCache() async {
    _log.trace("Loading cache");
    jwtToken = await AppLocalStorage().read(StorageKeys.jwtToken.name);
    roles = await AppLocalStorage().read(StorageKeys.roles.name);
    language = await AppLocalStorage().read(StorageKeys.language.name) ?? "en";
    username = await AppLocalStorage().read(StorageKeys.username.name);
    theme = await AppLocalStorage().read(StorageKeys.theme.name) ?? "classic";
    brightness = await AppLocalStorage().read(StorageKeys.brightness.name) ?? "light";
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

/// LocalStorage predefined keys
enum StorageKeys { jwtToken, roles, language, username, theme, brightness }

/// Application Local Storage
///
/// This class is used to store data locally with the help of shared preferences.
class SharedPreferencesStrategy implements StorageStrategy {
  static final _log = AppLogger.getLogger("AppLocalStorage");

  static final SharedPreferencesStrategy _instance = SharedPreferencesStrategy._internal();

  SharedPreferencesStrategy._internal();

  factory SharedPreferencesStrategy() {
    _log.trace("Creating AppLocalStorage instance");
    return _instance;
  }

  SharedPreferences? _prefsInstance;

  @visibleForTesting
  void setPreferencesInstance(SharedPreferences prefs) {
    _prefsInstance = prefs;
  }

  /// Shared Preferences private instance
  Future<SharedPreferences> get _prefs async => _prefsInstance ??= await SharedPreferences.getInstance();

  /// Save data to local storage <br>
  /// <br>
  /// This method saves data to local storage. It takes a key and a value as parameters.<br>
  /// Key is the string and value is dynamic.<br>
  /// Supported values:<br>
  /// - **String**
  /// - **int**
  /// - **double**
  /// - **bool**
  /// - **List String**
  /// <br>
  ///
  /// throws Exception if value type is not supported
  @override
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

  /// Get data from local storage <br>
  /// <br>
  /// This method gets data from local storage. It takes a key as parameter. <br>
  /// Supported values:<br>
  /// - **String**
  /// - **int**
  /// - **double**
  /// - **bool**
  /// - **List String**
  @override
  Future<dynamic> read(String key) async {
    _log.trace("Reading data from local storage");
    final prefs = await _prefs;
    final result = prefs.get(key);
    //_log.trace("Read data from local storage {} {}", [key, result]);
    return result;
  }

  /// Remove data from local storage
  ///
  /// This method removes data from local storage. It takes a key as parameter.
  @override
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

  /// Clear all data from local storage
  ///
  /// This method clears all data from local storage.
  @override
  Future<void> clear() async {
    _log.info("Clearing all data from local storage");
    final prefs = await _prefs;
    prefs.clear();
    await AppLocalStorageCached.loadCache();
    _log.info("Cleared all data from local storage");
  }
}

/// Application Local Storage with GetX
///
/// This class is used to store data locally with the help of get storage.
class GetStorageStrategy implements StorageStrategy {
  static final _log = AppLogger.getLogger("AppLocalStorageGetX");
  static final GetStorageStrategy _instance = GetStorageStrategy._internal();

  GetStorageStrategy._internal();

  factory GetStorageStrategy() {
    _log.trace("Creating AppLocalStorageGetX instance");
    return _instance;
  }

  GetStorage? _prefsInstance;

  @visibleForTesting
  void setPreferencesInstance(GetStorage prefs) {
    _prefsInstance = prefs;
  }

  /// GetStorage private instance
  Future<GetStorage> get _prefs async => _prefsInstance ??= GetStorage();

  /// Save data to local storage <br>
  @override
  Future<bool> save(String key, dynamic value) async {
    _log.trace("Saving data to local storage {} {}", [key, value]);
    final prefs = await _prefs;
    try {
      prefs.write(key, value);
      await AppLocalStorageCached.loadCache();
      _log.trace("Saved data to local storage {} {}", [key, value]);
      return true;
    } catch (e) {
      _log.error("Error saving data to local storage: {}, {}", [key, e]);
      return false;
    }
  }

  /// Get data from local storage <br>
  @override
  Future<dynamic> read(String key) async {
    _log.trace("Reading data from local storage");
    final prefs = await _prefs;
    final result = prefs.read(key);
    _log.trace("Read data from local storage {} {}", [key, result]);
    return result;
  }

  /// Remove data from local storage
  @override
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

  /// Clear all data from local storage
  @override
  Future<void> clear() async {
    _log.info("Clearing all data from local storage");
    final prefs = await _prefs;
    prefs.erase();
    await AppLocalStorageCached.loadCache();
    _log.info("Cleared all data from local storage");
  }
}

enum StorageType { sharedPreferences, getStorage }

class AppLocalStorage {
  static final _log = AppLogger.getLogger("AppLocalStorage");
  static final AppLocalStorage _instance = AppLocalStorage._internal();

  late StorageStrategy _strategy;

  AppLocalStorage._internal() {
    _log.trace("Creating AppLocalStorage instance");
    _strategy = SharedPreferencesStrategy();
  }

  factory AppLocalStorage() => _instance;

  void setStorage(StorageType type) {
    _log.trace("Setting storage strategy to {}", [type]);
    switch (type) {
      case StorageType.sharedPreferences:
        _strategy = SharedPreferencesStrategy();
        break;
      case StorageType.getStorage:
        _strategy = GetStorageStrategy();
        break;
    }
  }

  Future<bool> save(String key, dynamic value) async {
    final result = await _strategy.save(key, value);
    await AppLocalStorageCached.loadCache();
    return result;
  }

  Future<dynamic> read(String key) async {
    return await _strategy.read(key);
  }

  Future<bool> remove(String key) async {
    final result = await _strategy.remove(key);
    await AppLocalStorageCached.loadCache();
    return result;
  }

  Future<void> clear() async {
    await _strategy.clear();
    await AppLocalStorageCached.loadCache();
  }
}
