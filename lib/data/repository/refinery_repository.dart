import 'dart:developer';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';

import '../http_utils.dart';
import '../models/refinery.dart';

/// user repository
///
/// This class is responsible for all the user related operations
/// list, create, update, delete etc.
class RefineryRepository {
  final _path = "/refineries";
  /// Retrieve all refinery method that retrieves all the refinery
  Future<List<Refinery>> getRefineries() async {
    final refineryRequest = await HttpUtils.get("/refineries");
    return JsonMapper.deserialize<List<Refinery>>(refineryRequest)!;
  }

  /// Retrieve user method that retrieves a user by id
  ///
  /// @param id the user id
  Future<Refinery> getRefinery(String id) async {
    final userRequest = await HttpUtils.get("/refinery/$id");
    return JsonMapper.deserialize<Refinery>(userRequest)!;
  }

  /// Create user method that creates a new user
  ///
  /// @param user the user object
  Future<Refinery?> createRefinery(Refinery refinery) async {
    final saveRequest =
        await HttpUtils.postRequest<Refinery>("/refineries", refinery);
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
        ? JsonMapper.deserialize<Refinery>(saveRequest.body)
        : null;
  }

  /// Find user method that findRefinery a user
  Future<List<Refinery>> findRefinery(
    int rangeStart,
    int rangeEnd,
  ) async {
    final userRequest = await HttpUtils.get(
        "/admin/refinery?page=${rangeStart.toString()}&size=${rangeEnd.toString()}");
    var result = JsonMapper.deserialize<List<Refinery>>(userRequest)!;
    return result;
  }

  /// Find user method that findRefineryByAuthorities a user
  Future<List<Refinery>> findRefineryByAuthorities(
    int rangeStart,
    int rangeEnd,
    String authorities,
  ) async {
    final userRequest = await HttpUtils.get(
        "/admin/refinery","/authorities/$authorities?page=${rangeStart.toString()}&size=${rangeEnd.toString()}");
    var result = JsonMapper.deserialize<List<Refinery>>(userRequest)!;
    return result;
  }

  /// Find user method that findRefineryByName a user
  Future<List<Refinery>> findRefineryByName() async {
    
    final userRequest = await HttpUtils.get(_path,"?page=0&size=10");
    final result = JsonMapper.deserialize<List<Refinery>>(userRequest)!;
    return result;
  }

  /// Edit user method that editRefinery a user

  Future<Refinery?> updateRefinery(Refinery refinery) async {
    //api/refineries/{id}
    final saveRequest = await HttpUtils.putRequest<Refinery>(
        "/refineries/${refinery.id.toString()}", refinery);
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
        ? JsonMapper.deserialize<Refinery>(saveRequest.body)
        : null;
  }
}
