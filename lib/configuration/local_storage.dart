import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalStorageCached {
  static late String? jwtToken;
  static late List<String>? roles;
  static late String? language;
  static late String? username;

  static Future<void> loadCache() async {
    jwtToken = await AppLocalStorage().read(StorageKeys.jwtToken.name);
    roles = await AppLocalStorage().read(StorageKeys.roles.name);
    language = await AppLocalStorage().read(StorageKeys.language.name) ?? "en";
    username = await AppLocalStorage().read(StorageKeys.username.name);
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
  static final AppLocalStorage _instance = AppLocalStorage._internal();

  factory AppLocalStorage() {
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
      debugPrint("Saved data to local storage: $key - $value");
      return true;
    } catch (e) {
      debugPrint("Error saving data to local storage: $e");
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
    final prefs = await _prefs;
    return prefs.get(key);
  }

  /// Remove data from local storage
  ///
  /// This method removes data from local storage. It takes a key as parameter.
  Future<bool> remove(String key) async {
    try {
      final prefs = await _prefs;
      prefs.remove(key);
      await AppLocalStorageCached.loadCache();
      return true;
    } catch (e) {
      debugPrint("Error removing data from local storage: $e");
      return false;
    }
  }

  /// Clear all data from local storage
  ///
  /// This method clears all data from local storage.
  Future<void> clear() async {
    final prefs = await _prefs;
    prefs.clear();
    await AppLocalStorageCached.loadCache();
  }
}
