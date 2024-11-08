import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';

class AuthoritiesRepository {
  AuthoritiesRepository();

  final String _resource = "authorities";

  Future<List<String>> getAuthorities() async {
    final saveRequest = await HttpUtils.getRequest("/$_resource");
    List<String> authorities = JsonMapper.deserialize(saveRequest)!;
    authorities.remove("ROLE_USER");
    return authorities;
  }
}
