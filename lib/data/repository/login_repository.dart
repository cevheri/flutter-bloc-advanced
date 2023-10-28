import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../http_utils.dart';
import '../models/jwt_token.dart';
import '../models/user_jwt.dart';

class LoginRepository {
  LoginRepository();

  /// Store the JWT token in the secure storage
  Future<void> _storeToken(JWTToken result) async {
    FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.delete(key: HttpUtils.keyForJWTToken);
    await storage.write(key: HttpUtils.keyForJWTToken, value: result.idToken);
  }

  Future<JWTToken> authenticate(UserJWT userJWT) async {
    final authenticateRequest = await HttpUtils.postRequest<UserJWT>("/authenticate", userJWT);
    JWTToken result = JsonMapper.deserialize<JWTToken>(authenticateRequest.body)!;
    await _storeToken(result);
    return result;
  }



  Future<void> logout() async {
    FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.delete(key: HttpUtils.keyForJWTToken);
  }
}
