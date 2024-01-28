import 'package:dart_json_mapper/dart_json_mapper.dart';
import '../http_utils.dart';
import '../models/corporation.dart';

/// user repository
///
/// This class is responsible for all the user related operations
/// list, create, update, delete etc.
class CorporationRepository {
  final String _path = "/corporations";

  /// Retrieve all corporations method that retrieves all the corporations
  Future<List<Corporation>> getCorporations() async {
    final corporationsRequest = await HttpUtils.get(_path);
    return JsonMapper.deserialize<List<Corporation>>(corporationsRequest)!;
  }

  /// Retrieve user method that retrieves a user by id
  ///
  /// @param id the user id
  Future<Corporation> getCorporation(String id) async {
    final userRequest = await HttpUtils.get(_path,"corporations/$id");
    return JsonMapper.deserialize<Corporation>(userRequest)!;
  }

  /// Create user method that creates a new user
  ///
  /// @param user the user object
  Future<Corporation?> createCorporation(Corporation user) async {
    final saveRequest =
        await HttpUtils.postRequest<Corporation>(_path, user);
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
        ? JsonMapper.deserialize<Corporation>(saveRequest.body)
        : null;
  }

  /// Find user method that findCorporation a user
  Future<List<Corporation>> findCorporation(
    int page,
    int size
  ) async {
    final userRequest = await HttpUtils.get(
        "/admin/corporations?page=$page&size=$size");
    var result = JsonMapper.deserialize<List<Corporation>>(userRequest)!;
    return result;
  }

  /// Find user method that findCorporationByAuthorities a user
  Future<List<Corporation>> list() async {
    final response = await HttpUtils.get(_path,"?page=0&size=10&sort=id,asc");
    var result = JsonMapper.deserialize<List<Corporation>>(response)!; 
    return result;
  }

  /// Find user method that findCorporationByName a user
  Future<List<Corporation>> findCorporationByName(
    int page,
    int size,
    String name,
    String authorities,
  ) async {
    final userRequest = await HttpUtils.get(
        "/admin/corporations/filter?name=$name&authorities=$authorities&page=$page&size=$size");
    var result = JsonMapper.deserialize<List<Corporation>>(userRequest)!;
    return result;
  }

  /// Edit user method that editCorporation a user

  Future<Corporation?> updateCorporation(Corporation corporation) async {
    final saveRequest =
        await HttpUtils.putRequest<Corporation>("$_path/${corporation.id}", corporation);
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
        ? JsonMapper.deserialize<Corporation>(saveRequest.body)
        : null;
  }
}
