// import 'package:get_storage/get_storage.dart';
//
// //TODO storage alternatives:
// // - https://pub.dev/packages/localstorage
// // - https://pub.dev/packages/shared_preferences
// // - https://pub.dev/packages/hive
//
// class AuthenticationStorageConstants {
//   static const JWT_TOKEN = "TOKEN";
//   static const ROLES = "ROLES";
//   static const LANGUAGE = "LANGUAGE";
//   static const USERNAME = "USERNAME";
// }
//
// Map<String, dynamic> getStorageCache = {};
//
// Future<void> loadStorageData() async {
//   getStorageCache = await getStorage();
// }
//
// //TODO a lot of read to storage is done in the app
// Future<Map<String, dynamic>> getStorage() async {
//   final authenticationStorage = GetStorage();
//   final language = authenticationStorage.read(AuthenticationStorageConstants.LANGUAGE) ?? "";
//   final jwtToken = authenticationStorage.read(AuthenticationStorageConstants.JWT_TOKEN) ?? "";
//   final role = authenticationStorage.read(AuthenticationStorageConstants.ROLES) ?? "";
//   final username = authenticationStorage.read(AuthenticationStorageConstants.USERNAME) ?? "";
//
//   return {
//     "jwtToken": jwtToken,
//     "role": role,
//     "language": language,
//     "username": username,
//   };
// }
//
// void saveStorage({
//   String? jwtToken,
//   List<String>? roles,
//   String? language,
//   String? username,
// }) {
//   final authenticationStorage = GetStorage();
//   jwtToken != null ? authenticationStorage.write(AuthenticationStorageConstants.JWT_TOKEN, jwtToken) : null;
//   roles != null ? authenticationStorage.write(AuthenticationStorageConstants.ROLES, roles) : null;
//   language != null ? authenticationStorage.write(AuthenticationStorageConstants.LANGUAGE, language) : null;
//   username != null ? authenticationStorage.write(AuthenticationStorageConstants.USERNAME, username) : null;
//   getStorage();
//   loadStorageData();
// }
//
// void clearStorage() {
//   final authenticationStorage = GetStorage();
//   authenticationStorage.remove(AuthenticationStorageConstants.JWT_TOKEN);
//   authenticationStorage.remove(AuthenticationStorageConstants.ROLES);
//   authenticationStorage.remove(AuthenticationStorageConstants.LANGUAGE);
//   authenticationStorage.remove(AuthenticationStorageConstants.USERNAME);
//
//   authenticationStorage.erase();
// }
//
// // void clearLocalStorage() {
// //   html.window.localStorage.clear();
// // }
