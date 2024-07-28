import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_constants.dart';
import '../models/jwt_token.dart';
import '../models/user_jwt.dart';

class LoginRepository {
  LoginRepository();

  /// Store the JWT token in the secure storage
  Future<void> _storeToken(JWTToken result) async {
    AppConstants.jwtToken = result.idToken ?? "";
  }

  Future<JWTToken> authenticate(UserJWT userJWT) async {
    //final authenticateRequest = await HttpUtils.postRequest<UserJWT>("/authenticate", userJWT);
    //JWTToken result = JsonMapper.deserialize<JWTToken>(authenticateRequest.body)!;
    await _storeToken(JWTToken("admin"));
    return JWTToken("admin");
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('jwtToken');
    await prefs.clear();
    AppConstants.jwtToken = "";
  }
}
