import 'package:dart_json_mapper/dart_json_mapper.dart';
import '../http_utils.dart';
import '../models/user.dart';

/// user repository
///
/// This class is responsible for all the user related operations
/// list, create, update, delete etc.
class UserRepository {
  final _path = "/admin/users";

  /// Retrieve all users method that retrieves all the users
  Future<List<User>> getUsers() async {
    final usersRequest = await HttpUtils.get("/users");
    return JsonMapper.deserialize<List<User>>(usersRequest)!;
  }

  /// Retrieve user method that retrieves a user by id
  ///
  /// @param id the user id
  Future<User> getUser(String id) async {
    final userRequest = await HttpUtils.get("/users/$id");
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

    return result == HttpUtils.successResult ? JsonMapper.deserialize<User>(saveRequest.body) : null;
  }

  /// Find user method that findUser a user
  Future<List<User>> listUser(
    int page,
    int size,
  ) async {
    final userRequest = await HttpUtils.get("/admin/users?page=$page&size=$size");
    var result = JsonMapper.deserialize<List<User>>(userRequest)!;
    return result;
  }

  /// Find user method that findUserByAuthorities a user
  Future<List<User>> findUserByAuthorities(
    int page,
    int size,
    String authorities,
  ) async {
    final userRequest = await HttpUtils.get(_path, "/authorities/$authorities?page=$page&size=$size");
    var result = JsonMapper.deserialize<List<User>>(userRequest)!;
    return result;
  }

  /// Find user method that findUserByName a user
  Future<List<User>> findUserByName(
    int page,
    int size,
    String name,
    String authorities,
  ) async {
    final userRequest = await HttpUtils.get(_path, "/filter?name=$name&authorities=$authorities&page=$page&size=$size");
    return JsonMapper.deserialize<List<User>>(userRequest)!;
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

    return result == HttpUtils.successResult ? JsonMapper.deserialize<User>(saveRequest.body) : null;
  }
}
