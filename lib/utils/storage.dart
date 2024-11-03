import 'package:get_storage/get_storage.dart';
import 'dart:html' as html;

class AuthenticationStorageConstants {
  static const JWT_TOKEN = "TOKEN";
  static const ROLE = "ROLE";
  static const LANGUAGE = "LANGUAGE";
  static const USERNAME = "USERNAME";
}

Future<Map<String, dynamic>> getStorage() async {
  final authenticationStorage = GetStorage();
  final language = authenticationStorage.read(AuthenticationStorageConstants.LANGUAGE) ?? "";
  final jwtToken = authenticationStorage.read(AuthenticationStorageConstants.JWT_TOKEN) ?? "";
  final role = authenticationStorage.read(AuthenticationStorageConstants.ROLE) ?? "";
  final username = authenticationStorage.read(AuthenticationStorageConstants.USERNAME) ?? "";

  return {
    "jwtToken": jwtToken,
    "role": role,
    "language": language,
    "username": username,
  };
}

void saveStorage({
  String? jwtToken,
  String? role,
  String? language,
  String? username,
}) {
  final authenticationStorage = GetStorage();
  jwtToken != null ? authenticationStorage.write(AuthenticationStorageConstants.JWT_TOKEN, jwtToken) : null;
  role != null ? authenticationStorage.write(AuthenticationStorageConstants.ROLE, role) : null;
  language != null ? authenticationStorage.write(AuthenticationStorageConstants.LANGUAGE, language) : null;
  username != null ? authenticationStorage.write(AuthenticationStorageConstants.USERNAME, username) : null;
  getStorage();
}

void clearStorage() {
  final authenticationStorage = GetStorage();
  clearLocalStorage();
  authenticationStorage.remove(AuthenticationStorageConstants.JWT_TOKEN);
  authenticationStorage.remove(AuthenticationStorageConstants.ROLE);
  authenticationStorage.remove(AuthenticationStorageConstants.LANGUAGE);
}

void clearLocalStorage() {
  html.window.localStorage.clear();
}
