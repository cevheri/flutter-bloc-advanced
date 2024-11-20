import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/http_utils.dart';
import 'package:flutter_bloc_advance/data/models/authority.dart';

class AuthorityRepository {
  AuthorityRepository();

  final String _resource = "authorities";

  Future<Authority?> createAuthority(Authority authority) async {
    debugPrint("BEGIN:createAuthority repository start");
    if (authority.name == null || authority.name!.isEmpty) {
      throw BadRequestException("Authority name null");
    }
    final httpResponse = await HttpUtils.postRequest<Authority>("/$_resource", authority);
    final response = Authority.fromJsonString(httpResponse.body);
    debugPrint("END:createAuthority successful");
    return response;
  }

  Future<List<String?>> getAuthorities() async {
    debugPrint("BEGIN:getAuthorities repository start");
    final httpResponse = await HttpUtils.getRequest("/$_resource");
    final response = Authority.fromJsonStringList(httpResponse.body);
    debugPrint("END:getAuthorities successful");
    return response;
  }

  Future<Authority?> getAuthority(String id) async {
    debugPrint("BEGIN:getAuthority repository start");
    if (id.isEmpty) {
      throw BadRequestException("Authority id null");
    }
    final httpResponse = await HttpUtils.getRequest("/$_resource/$id");
    final response = Authority.fromJsonString(httpResponse.body);
    debugPrint("END:getAuthority successful");
    return response;
  }

  Future<void> deleteAuthority(String id) async {
    debugPrint("BEGIN:deleteAuthority repository start");
    if (id.isEmpty) {
      throw BadRequestException("Authority id null");
    }
    await HttpUtils.deleteRequest("/$_resource/$id");
    debugPrint("END:deleteAuthority successful");
  }
}
