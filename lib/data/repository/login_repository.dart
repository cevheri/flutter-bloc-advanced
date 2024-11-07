import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/utils/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../configuration/environment.dart';
import '../../utils/app_constants.dart';
import '../http_utils.dart';
import '../models/jwt_token.dart';
import '../models/user_jwt.dart';

class LoginRepository {
  LoginRepository();

  // /// Store the JWT token in the secure storage
  // Future<void> _storeToken(JWTToken result) async {
  //   AppConstants.jwtToken = result.idToken ?? "";
  // }

  //TODO if (ProfileConstants.isProduction) {}
  Future<JWTToken> authenticate(UserJWT userJWT) async {
    if (ProfileConstants.isProduction) {
      final authenticateRequest = await HttpUtils.postRequest<UserJWT>("/authenticate", userJWT);
      JWTToken result = JsonMapper.deserialize<JWTToken>(authenticateRequest.body)!;
      saveStorage(jwtToken: result.idToken);
      return result;
    }
    else{
      JWTToken result = JsonMapper.deserialize<JWTToken>(await rootBundle.loadString('assets/mock/id_token.json'))!;
      saveStorage(jwtToken: result.idToken);
      return result;
      //
    }
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('jwtToken');
    await prefs.clear();
    clearStorage();
    clearLocalStorage();
  }
}
