import 'package:flutter_bloc_advance/utils/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../http_utils.dart';
import '../models/jwt_token.dart';
import '../models/user_jwt.dart';

class LoginRepository {
  LoginRepository();

  /// Authenticate the user with the given [userJWT].
  /// If the authentication is successful, the JWT token is saved in the storage.
  /// Returns the JWT token.
  /// Throws an exception if the username or password is invalid.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// curl 'https://dhw-api.onrender.com/api/authenticate' \
  ///   -H 'accept: application/json, text/plain, */*' \
  ///   -H 'content-type: application/json' \
  ///   --data-raw $'{"username":"admin","password":"admin","rememberMe":false}'
  /// ```
  Future<JWTToken> authenticate(UserJWT userJWT) async {
    JWTToken? result;
    if (userJWT.username == null || userJWT.password == null) {
      throw Exception("Invalid username or password");
    }

    final response = await HttpUtils.postRequest<UserJWT>("/authenticate", userJWT);
    result = JWTToken.fromJsonString(response.body);

    if (result != null && result.idToken != null) {
      saveStorage(jwtToken: result.idToken);
      return result;
    }
    return JWTToken(idToken: null);
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('jwtToken');
    await prefs.clear();
    clearStorage();
  }
}
