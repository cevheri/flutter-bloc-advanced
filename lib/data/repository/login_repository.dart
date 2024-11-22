import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';

import '../http_utils.dart';
import '../models/jwt_token.dart';
import '../models/user_jwt.dart';

class LoginRepository {
  static final _log = AppLogger.getLogger("LoginRepository");

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
  Future<JWTToken?> authenticate(UserJWT userJWT) async {
    _log.debug("BEGIN:authenticate repository start username: {}", [userJWT.username]);
    JWTToken? result;
    if (userJWT.username == null || userJWT.username!.isEmpty || userJWT.password == null || userJWT.password!.isEmpty) {
      throw Exception("Invalid username or password");
    }

    final response = await HttpUtils.postRequest<UserJWT>("/authenticate", userJWT);
    result = JWTToken.fromJsonString(response.body);

    if (result != null && result.idToken != null) {
      await AppLocalStorage().save(StorageKeys.jwtToken.name, result.idToken);
    }
    _log.debug("END:authenticate successful - response.body: {}", [result.toString()]);
    return result;
  }

  Future<void> logout() async {
    _log.debug("BEGIN:logout repository start");
    await AppLocalStorage().clear();
    _log.debug("END:logout successful");
  }
}
