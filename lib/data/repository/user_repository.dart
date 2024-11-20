import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';

import '../http_utils.dart';
import '../models/user.dart';

/// user repository
///
/// This class is responsible for all the user related operations
/// list, create, update, delete etc.
class UserRepository {
  static const String _resource = "users";
  static const String userIdRequired = "User id is required";

  /// Retrieve all users method that retrieves all the users
  Future<List<User?>> getUsers({int page = 0, int size = 10, List<String> sort = const ["id,desc"]}) async {
    debugPrint("BEGIN:getUsers repository start");
    final httpResponse = await HttpUtils.getRequest("/admin/$_resource?page=$page&size=$size&sort=${sort.join("&sort=")}");
    final response = User.fromJsonStringList(httpResponse.body);
    debugPrint("END:getUsers successful");
    return response;
  }

  /// Retrieve user method that retrieves a user by id
  ///
  /// @param id the user id
  Future<User?> getUser(String id) async {
    debugPrint("BEGIN:getUser repository start");
    if (id.isEmpty) {
      throw BadRequestException(userIdRequired);
    }
    final httpResponse = await HttpUtils.getRequest("/admin/$_resource/$id");
    final response = User.fromJsonString(httpResponse.body)!;
    debugPrint("END:getUser successful");
    return response;
  }

  /// Retrieve user method that retrieves a user by username
  ///
  /// @param login the username
  Future<User?> getUserByLogin(String login) async {
    debugPrint("BEGIN:getUserByLogin repository start");
    if (login.isEmpty) {
      throw BadRequestException("User login is required");
    }
    final httpResponse = await HttpUtils.getRequest("/admin/$_resource/$login");
    final response = User.fromJsonString(httpResponse.body)!;
    debugPrint("END:getUserByLogin successful");
    return response;
  }

  /// Create user method that creates a new user
  ///
  /// @param user the user object
  Future<User?> createUser(User user) async {
    debugPrint("BEGIN:createUser repository start");
    if (user.login == null || user.login!.isEmpty) {
      throw BadRequestException("User login is required");
    }
    if (user.email == null || user.email!.isEmpty) {
      throw BadRequestException("User email is required");
    }
    final httpResponse = await HttpUtils.postRequest<User>("/admin/$_resource", user);
    final response = User.fromJsonString(httpResponse.body);
    debugPrint("END:createUser successful");
    return response;
  }

  /// Find user method that findUser a user
  Future<List<User>> listUser(int rangeStart, int rangeEnd, {List<String> sort = const ["id,desc"]}) async {
    final response = await HttpUtils.getRequest("/admin/$_resource?page=$rangeStart&size=$rangeEnd&sort=${sort.join("&sort=")}");
    var result = JsonMapper.deserialize<List<User>>(response.body)!;
    return result;
  }

  /// Find user method that findUserByAuthorities a user
  Future<List<User>> findUserByAuthority(int rangeStart, int rangeEnd, String authority) async {
    final response = await HttpUtils.getRequest("/admin/$_resource/list");
    var result = JsonMapper.deserialize<List<User>>(response.body)!;
    return result;
  }

  /// Find user method that findUserByName a user
  Future<List<User>> findUserByName(int rangeStart, int rangeEnd, String name, String authority) async {
    final response = await HttpUtils.getRequest(
        "/admin/$_resource/filter?name=$name&authority=$authority&page=${rangeStart.toString()}&size=${rangeEnd.toString()}");
    var result = JsonMapper.deserialize<List<User>>(response.body)!;
    return result;
  }

  /// Edit user method that editUser a user
  Future<User?> updateUser(User user) async {
    debugPrint("BEGIN:updateUser repository start");
    if(user.id == null || user.id!.isEmpty) {
      throw BadRequestException(userIdRequired);
    }
    final httpResponse = await HttpUtils.putRequest<User>("/admin/$_resource", user);
    final response = User.fromJsonString(httpResponse.body);
    debugPrint("END:updateUser successful");
    return response;
  }

  Future<void> deleteUser(String id) async {
    debugPrint("BEGIN:deleteUser repository start");
    if(id.isEmpty) {
      throw BadRequestException(userIdRequired);
    }
    await HttpUtils.deleteRequest("/admin/$_resource/$id");
    debugPrint("END:deleteUser successful");
  }
}
