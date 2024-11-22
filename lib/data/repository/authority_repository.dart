import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/http_utils.dart';
import 'package:flutter_bloc_advance/data/models/authority.dart';

class AuthorityRepository {
  static final _log = AppLogger.getLogger("AuthorityRepository");

  AuthorityRepository();

  final String _resource = "authorities";

  Future<Authority?> createAuthority(Authority authority) async {
    _log.debug("BEGIN:createAuthority repository start : {}", [authority.toString()]);
    if (authority.name == null || authority.name!.isEmpty) {
      throw BadRequestException("Authority name null");
    }
    final httpResponse = await HttpUtils.postRequest<Authority>("/$_resource", authority);
    final response = Authority.fromJsonString(httpResponse.body);
    _log.debug("END:createAuthority successful");
    return response;
  }

  Future<List<String?>> getAuthorities() async {
    _log.debug("BEGIN:getAuthorities repository start");
    final httpResponse = await HttpUtils.getRequest("/$_resource");
    final response = Authority.fromJsonStringList(httpResponse.body);
    _log.debug("END:getAuthorities successful - response list size: {}", [response.length]);
    return response;
  }

  Future<Authority?> getAuthority(String id) async {
    _log.debug("BEGIN:getAuthority repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException("Authority id null");
    }
    final httpResponse = await HttpUtils.getRequest("/$_resource/$id");
    final response = Authority.fromJsonString(httpResponse.body);
    _log.debug("END:getAuthority successful - response.body: {}", [response.toString()]);
    return response;
  }

  Future<void> deleteAuthority(String id) async {
    _log.debug("BEGIN:deleteAuthority repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException("Authority id null");
    }
    final httpResponse = await HttpUtils.deleteRequest("/$_resource/$id");
    _log.debug("END:deleteAuthority successful - response status code: {}", [httpResponse.statusCode]);
  }
}
