import 'dart:developer';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';

import '../http_utils.dart';
import '../models/corporation_maturity.dart';

/// corporationMaturity repository
///
/// This class is responsible for all the corporationMaturity related operations
/// list, create, update, delete etc.
class CorporationMaturityRepository {
  final String _path = "/corporation-maturity-dates";

  /// Retrieve all corporationMaturities method that retrieves all the corporationMaturites
  Future<List<CorporationMaturity>> getCorporationMaturities() async {
    final request = await HttpUtils.get("/corporationMaturitys");
    return JsonMapper.deserialize<List<CorporationMaturity>>(request)!;
  }

  /// Retrieve corporationMaturity method that retrieves a corporationMaturity by id
  ///
  /// @param id the corporationMaturity id
  Future<List<CorporationMaturity>> getCorporationMaturity(String id) async {
    final response = await HttpUtils.get(_path, "/corporation/$id");
    final result = JsonMapper.deserialize<List<CorporationMaturity>>(response)!;
    return result;
  }

  /// Create corporationMaturity method that creates a new corporationMaturity
  ///
  /// @param corporationMaturity the corporationMaturity object
  Future<CorporationMaturity?> createCorporationMaturity(CorporationMaturity corporationMaturity) async {
    //api/corporation-maturity-dates
    final saveRequest = await HttpUtils.postRequest<CorporationMaturity>(_path, corporationMaturity);
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

    return result == HttpUtils.successResult ? JsonMapper.deserialize<CorporationMaturity>(saveRequest.body) : null;
  }

  /// Find corporationMaturity method that findCorporationMaturity a corporationMaturity
  Future<List<CorporationMaturity>> findCorporationMaturity(
    int page,
    int size,
  ) async {
    final response = await HttpUtils.get(_path,"?page=$page&size=$size&sort=id,asc");

    return JsonMapper.deserialize<List<CorporationMaturity>>(response)!;
  }

  /// Find corporationMaturity method that findCorporationMaturityByAuthorities a corporationMaturity
  Future<List<CorporationMaturity>> findCorporationMaturityByAuthorities(
    int page,
    int size,
    String authorities,
  ) async {
    final response =
        await HttpUtils.get(_path,"/authorities/$authorities?page=$page&size=$size");
    var result = JsonMapper.deserialize<List<CorporationMaturity>>(response)!;
    return result;
  }

  /// Find corporationMaturity method that findCorporationMaturityByName a corporationMaturity
  Future<List<CorporationMaturity>> findCorporationMaturityByName(
    int page,
    int size,
    String name,
  ) async {
    final corporationMaturityRequest =
        await HttpUtils.get(_path,"/filter/$name?page=$page&size=$size");
    var result = JsonMapper.deserialize<List<CorporationMaturity>>(corporationMaturityRequest)!;
    return result;
  }

  /// Delete corporationMaturity method that deletes a corporationMaturity by id
  ///
  /// @param id the corporationMaturity id
  Future<bool?> deleteCorporationMaturity(String id) async {
    //api/corporation-maturity-dates/{id}
    final result = await HttpUtils.deleteRequest("$_path/$id");
    if (result.statusCode == 204) {
      return true;
    }
    return false;
  }

  /// Update corporationMaturity method that updates a corporationMaturity
  ///
  /// @param corporationMaturity the corporationMaturity object
  Future<CorporationMaturity?> updateCorporationMaturity(
      //api/corporation-maturity-dates/{id}
      CorporationMaturity corporationMaturity) async {
    final result = await HttpUtils.putRequest("$_path/${corporationMaturity.id}", corporationMaturity);
    if (result.statusCode == 200) {
      return JsonMapper.deserialize<CorporationMaturity>(result.body);
    }
    return null;
  }
}
