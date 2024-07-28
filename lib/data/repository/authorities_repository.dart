import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';


class AuthoritiesRepository {
  AuthoritiesRepository();
  Future<List<String>> getAuthorities() async {
    //final saveRequest = await HttpUtils.getRequest("/authorities");
    List<String> authorities = JsonMapper.deserialize(await rootBundle.loadString('mock/authorities.json'))!;
    authorities.remove ("ROLE_USER");
    return authorities;
  }
}

