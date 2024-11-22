import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalStorageCached {
  static final _log = AppLogger.getLogger("AppLocalStorageCached");
  static late String? jwtToken;
  static late List<String>? roles;
  static late String? language;
  static late String? username;

  static Future<void> loadCache() async {
    _log.trace("Loading cache");
    jwtToken = await AppLocalStorage().read(StorageKeys.jwtToken.name);
    roles = await AppLocalStorage().read(StorageKeys.roles.name);
    language = await AppLocalStorage().read(StorageKeys.language.name) ?? "en";
    username = await AppLocalStorage().read(StorageKeys.username.name);
    _log.trace("Loaded cache with username:{}, roles:{}, language:{}, jwtToken:{}", [username, roles, language, jwtToken]);
  }
}

/// LocalStorage predefined keys
enum StorageKeys { jwtToken, roles, language, username }

// extension StorageKeysExtension on StorageKeys {
//   String get name {
//     switch (this) {
//       case StorageKeys.jwtToken:
//         return "TOKEN";
//       case StorageKeys.roles:
//         return "ROLES";
//       case StorageKeys.language:
//         return "LANGUAGE";
//       case StorageKeys.username:
//         return "USERNAME";
//       default:
//         return "";
//     }
//   }
// }

/// Application Local Storage
///
/// This class is used to store data locally with the help of shared preferences.
class AppLocalStorage {
  static final _log = AppLogger.getLogger("AppLocalStorage");
  static final AppLocalStorage _instance = AppLocalStorage._internal();

  factory AppLocalStorage() {
    _log.trace("Creating AppLocalStorage instance");
    return _instance;
  }

  AppLocalStorage._internal();

  /// Shared Preferences private instance
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

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
  Future<bool> save(String key, dynamic value) async {
    _log.trace("Saving data to local storage");
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
  Future<dynamic> read(String key) async {
    _log.trace("Reading data from local storage");
    final prefs = await _prefs;
    final result = prefs.get(key);
    _log.trace("Read data from local storage {} {}", [key, result]);
    return result;
  }

  /// Remove data from local storage
  ///
  /// This method removes data from local storage. It takes a key as parameter.
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
  Future<void> clear() async {
    _log.info("Clearing all data from local storage");
    final prefs = await _prefs;
    prefs.clear();
    await AppLocalStorageCached.loadCache();
    _log.info("Cleared all data from local storage");
  }
}
