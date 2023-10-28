import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';
import '../models/user.dart';

/// user repository
///
/// This class is responsible for all the user related operations
/// list, create, update, delete etc.
class UserRepository {
  /// Retrieve all users method that retrieves all the users
  Future<List<User>> getUsers() async {
    final usersRequest = await HttpUtils.getRequest("/users");
    return JsonMapper.deserialize<List<User>>(usersRequest.body)!;
  }

  /// Retrieve user method that retrieves a user by id
  ///
  /// @param id the user id
  Future<User> getUser(String id) async {
    final userRequest = await HttpUtils.getRequest("/users/$id");
    return JsonMapper.deserialize<User>(userRequest.body)!;
  }

  /// Create user method that creates a new user
  ///
  /// @param user the user object
  Future<String?> createUser(User user) async {
    final saveRequest = await HttpUtils.postRequest<User>("/users", user);
    String? result;
    if (saveRequest.statusCode != 200) {
      if (saveRequest.headers[HttpUtils.errorHeader] != null) {
        result = saveRequest.headers[HttpUtils.errorHeader];
      } else {
        result = HttpUtils.errorServerKey;
      }
    } else {
      result = HttpUtils.successResult;
    }

    return result;
  }

  /// Update user method that updates a user
  ///
  /// @param user the user object
  updateUser(User user, String id) {
    return HttpUtils.putRequest<User>("/users/$id", user);
  }

  /// Delete user method that deletes a user
  ///
  /// @param id the user id
  deleteUser(String id) {
    return HttpUtils.deleteRequest("/users/$id");
  }
}