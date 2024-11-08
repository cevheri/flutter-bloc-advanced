import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter_bloc_advance/utils/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../http_utils.dart';
import '../models/jwt_token.dart';
import '../models/user_jwt.dart';

class LoginRepository {
  LoginRepository();

  Future<JWTToken> authenticate(UserJWT userJWT) async {
    JWTToken? result;
    if (userJWT.username == null || userJWT.password == null) {
      throw Exception("Invalid username or password");
    }

    final authenticateRequest = await HttpUtils.postRequest<UserJWT>("/authenticate", userJWT);
    result = JsonMapper.deserialize<JWTToken>(authenticateRequest.body)!;

    if (result.idToken != null) {
      saveStorage(jwtToken: result.idToken);
    }
    return result;
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('jwtToken');
    await prefs.clear();
    clearStorage();
  }
}
