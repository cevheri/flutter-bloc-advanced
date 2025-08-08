import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';

import '../http_utils.dart';
import '../models/user.dart';

/// user repository
///
/// This class is responsible for all the user related operations
/// list, create, update, delete etc.
class UserRepository {
  static final _log = AppLogger.getLogger("UserRepository");
  static const String _resource = "users";
  static const String userIdRequired = "User id is required";

  /// Retrieve user method that retrieves a user by id
  ///
  /// @param id the user id
  Future<User?> retrieve(String id) async {
    _log.debug("BEGIN:getUser repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException(userIdRequired);
    }
    final pathParams = id;
    final httpResponse = await HttpUtils.getRequest("/admin/$_resource", pathParams: pathParams);
    final response = User.fromJsonString(httpResponse.body)!;
    _log.debug("END:getUser successful - response.body: {}", [response.toString()]);
    return response;
  }

  /// Retrieve user method that retrieves a user by username
  ///
  /// @param login the username
  Future<User?> retrieveByLogin(String login) async {
    _log.debug("BEGIN:getUserByLogin repository start - login: {}", [login]);
    if (login.isEmpty) {
      throw BadRequestException("User login is required");
    }
    final pathParams = login;
    final httpResponse = await HttpUtils.getRequest("/admin/$_resource", pathParams: pathParams);
    final response = User.fromJsonString(httpResponse.body)!;
    _log.debug("END:getUserByLogin successful - response.body: {}", [response.toString()]);
    return response;
  }

  /// Create user method that creates a new user
  ///
  /// @param user the user object
  Future<User?> create(User user) async {
    _log.debug("BEGIN:createUser repository start : {}", [user.toString()]);
    if (user.login == null || user.login!.isEmpty) {
      throw BadRequestException("User login is required");
    }
    if (user.email == null || user.email!.isEmpty) {
      throw BadRequestException("User email is required");
    }
    final httpResponse = await HttpUtils.postRequest<User>("/admin/$_resource", user);
    final response = User.fromJsonString(httpResponse.body);
    _log.debug("END:createUser successful");
    return response;
  }

  /// Edit user method that editUser a user
  Future<User?> update(User user) async {
    _log.debug("BEGIN:updateUser repository start : {}", [user.toString()]);
    if (user.id == null || user.id!.isEmpty) {
      throw BadRequestException(userIdRequired);
    }
    final httpResponse = await HttpUtils.putRequest<User>("/admin/$_resource", user);
    final response = User.fromJsonString(httpResponse.body);
    _log.debug("END:updateUser successful");
    return response;
  }

  /// Retrieve all users method that retrieves all the users
  Future<List<User>> list({int page = 0, int size = 10, List<String> sort = const ["id,desc"]}) async {
    _log.debug("BEGIN:getUsers repository start - page: {}, size: {}, sort: {}", [page, size, sort]);
    final queryParams = {"page": page.toString(), "size": size.toString(), "sort": sort.join("&sort=")};
    final httpResponse = await HttpUtils.getRequest("/admin/$_resource", queryParams: queryParams);
    final response = User.fromJsonStringList(httpResponse.body);
    _log.debug("END:getUsers successful - response list size: {}", [response.length]);
    return response;
  }

  /// Find user method that findUserByAuthorities a user
  Future<List<User>> listByAuthority(int page, int size, String authority) async {
    _log.debug("BEGIN:findUserByAuthority repository start - page: {}, size: {}, authority: {}", [
      page,
      size,
      authority,
    ]);
    final queryParams = {"page": page.toString(), "size": size.toString()};
    final pathParams = authority;
    final response = await HttpUtils.getRequest(
      "/admin/$_resource/authorities",
      pathParams: pathParams,
      queryParams: queryParams,
    );
    // var r = response.body;
    var result = JsonMapper.deserialize<List<User>>(response.body)!;
    _log.debug("END:findUserByAuthority successful - response list size: {}", [result.length]);
    return result;
  }

  /// Find user method that findUserByName a user
  Future<List<User>> listByNameAndRole(int page, int size, String name, String authority) async {
    _log.debug("BEGIN:findUserByName repository start - page: {}, size: {}, name: {}, authority: {}", [
      page,
      size,
      name,
      authority,
    ]);
    final queryParams = {"page": page.toString(), "size": size.toString(), "name": name, "authority": authority};
    final response = await HttpUtils.getRequest("/admin/$_resource/filter", queryParams: queryParams);
    var result = JsonMapper.deserialize<List<User>>(response.body)!;
    _log.debug("END:findUserByName successful - response list size: {}", [result.length]);
    return result;
  }

  Future<void> delete(String id) async {
    _log.debug("BEGIN:deleteUser repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException(userIdRequired);
    }
    final pathParams = id;
    final httpResponse = await HttpUtils.deleteRequest("/admin/$_resource", pathParams: pathParams);
    _log.debug("END:deleteUser successful - response status code: {}", [httpResponse.statusCode]);
  }
}
