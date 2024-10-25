import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';

class AuthoritiesRepository {
  AuthoritiesRepository();
  Future<List<String>> getAuthorities() async {
    final saveRequest = await HttpUtils.getRequest("/authorities");
    List<String> authorities = JsonMapper.deserialize(saveRequest)!;
    authorities.remove("ROLE_USER");
    return authorities;
  }
}
