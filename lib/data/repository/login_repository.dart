import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';

import '../../configuration/environment.dart';
import '../../main/main_local.dart';
import '../../utils/storage.dart';
import '../http_utils.dart';
import '../models/jwt_token.dart';
import '../models/user_jwt.dart';

class LoginRepository {
  LoginRepository();

  Future<JWTToken> authenticate(UserJWT userJWT) async {
    if (ProfileConstants.isProduction) {
      final authenticateRequest = await HttpUtils.postRequest<UserJWT>("/authenticate", userJWT);
      JWTToken result = JsonMapper.deserialize<JWTToken>(authenticateRequest.body)!;
      saveStorage(jwtToken: result.idToken);
      loadStorageData();
      return result;
    } else {
      JWTToken result = JsonMapper.deserialize<JWTToken>(await rootBundle.loadString('assets/mock/id_token.json'))!;
      saveStorage(jwtToken: result.idToken);
      loadStorageData();
      return result;
      //
    }
  }

  Future<void> logout() async {
    clearStorage();
  }
}
