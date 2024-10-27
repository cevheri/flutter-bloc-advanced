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
    return JsonMapper.deserialize<List<User>>(usersRequest)!;
  }

  /// Retrieve user method that retrieves a user by id
  ///
  /// @param id the user id
  Future<User> getUser(String id) async {
    final userRequest = await HttpUtils.getRequest("/users/$id");
    return JsonMapper.deserialize<User>(userRequest)!;
  }

  /// Create user method that creates a new user
  ///
  /// @param user the user object
  Future<User?> createUser(User user) async {
    final saveRequest = await HttpUtils.postRequest<User>("/admin/users", user);
    String? result;

    if (saveRequest.statusCode != 201) {
      if (saveRequest.headers[HttpUtils.errorHeader] != null) {
        result = saveRequest.headers[HttpUtils.errorHeader];
      } else {
        result = HttpUtils.errorServerKey;
      }
    } else {
      result = HttpUtils.successResult;
    }

    return result == HttpUtils.successResult
        ? JsonMapper.deserialize<User>(saveRequest.body)
        : null;
  }

  /// Find user method that findUser a user
  Future<List<User>> listUser(
    int rangeStart,
    int rangeEnd,
  ) async {
    final userRequest = await HttpUtils.getRequest(
        "/admin/users?page=${rangeStart.toString()}&size=${rangeEnd.toString()}");
    var result = JsonMapper.deserialize<List<User>>(userRequest)!;
    return result;
  }

  /// Find user method that findUserByAuthorities a user
  Future<List<User>> findUserByAuthorities(
    int rangeStart,
    int rangeEnd,
    String authorities,
  ) async {
    final userRequest = await HttpUtils.getRequest(
        "/admin/users/list");
    var result = JsonMapper.deserialize<List<User>>(userRequest)!;
    return result;
  }

  /// Find user method that findUserByName a user
  Future<List<User>> findUserByName(
    int rangeStart,
    int rangeEnd,
    String name,
    String authorities,
  ) async {
    final userRequest = await HttpUtils.getRequest(
        "/admin/users/filter?name=$name&authorities=$authorities&page=${rangeStart.toString()}&size=${rangeEnd.toString()}");
    var result = JsonMapper.deserialize<List<User>>(userRequest)!;
    return result;
  }

  /// Edit user method that editUser a user

  Future<User?> updateUser(User user) async {
    final saveRequest = await HttpUtils.putRequest<User>("/admin/users", user);
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

    return result == HttpUtils.successResult
        ? JsonMapper.deserialize<User>(saveRequest.body)
        : null;
  }
}
