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
  /// Retrieve all corporationMaturitys method that retrieves all the corporationMaturitys
  Future<List<CorporationMaturity>> getCorporationMaturitys() async {
    final corporationMaturitysRequest =
        await HttpUtils.getRequest("/corporationMaturitys");
    return JsonMapper.deserialize<List<CorporationMaturity>>(
        corporationMaturitysRequest)!;
  }

  /// Retrieve corporationMaturity method that retrieves a corporationMaturity by id
  ///
  /// @param id the corporationMaturity id
  Future<List<CorporationMaturity>> getCorporationMaturity(String id) async {
    //final result = await HttpUtils.getRequest("/corporation-maturity-dates/corporation/$id?page=0&size=1000");
    //var defaultCityList = JsonMapper.deserialize<List<CorporationMaturity>>(result)!;
    var result = JsonMapper.deserialize<List<CorporationMaturity>>(await rootBundle.loadString('mock/ana_firma_vadeler.json'))!;
    print(result.length);
    var sortWithNameResult = result ..sort((a, b) => a.id!.compareTo(b.id!));
    return sortWithNameResult;
  }

  /// Create corporationMaturity method that creates a new corporationMaturity
  ///
  /// @param corporationMaturity the corporationMaturity object
  Future<CorporationMaturity?> createCorporationMaturity(
      CorporationMaturity corporationMaturity) async {
    //api/corporation-maturity-dates
    final saveRequest = await HttpUtils.postRequest<CorporationMaturity>(
        "/corporation-maturity-dates", corporationMaturity);
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
        ? JsonMapper.deserialize<CorporationMaturity>(saveRequest.body)
        : null;
  }

  /// Find corporationMaturity method that findCorporationMaturity a corporationMaturity
  Future<List<CorporationMaturity>> findCorporationMaturity(
    int rangeStart,
    int rangeEnd,
  ) async {


    final getRequest = await HttpUtils.getRequest(
        "/corporationMaturitys?page=${rangeStart.toString()}&size=${rangeEnd.toString()}");

    return JsonMapper.deserialize<List<CorporationMaturity>>(getRequest)!;
  }

  /// Find corporationMaturity method that findCorporationMaturityByAuthorities a corporationMaturity
  Future<List<CorporationMaturity>> findCorporationMaturityByAuthorities(
    int rangeStart,
    int rangeEnd,
    String authorities,
  ) async {
    final corporationMaturityRequest = await HttpUtils.getRequest(
        "/corporationMaturitys/authorities/$authorities?page=${rangeStart.toString()}&size=${rangeEnd.toString()}");
    var result =
        JsonMapper.deserialize<List<CorporationMaturity>>(corporationMaturityRequest)!;
    return result;
  }

  /// Find corporationMaturity method that findCorporationMaturityByName a corporationMaturity
  Future<List<CorporationMaturity>> findCorporationMaturityByName(
    int rangeStart,
    int rangeEnd,
    String name,
  ) async {
    final corporationMaturityRequest = await HttpUtils.getRequest(
        "/corporationMaturitys/filter/$name?page=${rangeStart.toString()}&size=${rangeEnd.toString()}");
    var result =
        JsonMapper.deserialize<List<CorporationMaturity>>(corporationMaturityRequest)!;
    return result;
  }

  /// Delete corporationMaturity method that deletes a corporationMaturity by id
  ///
  /// @param id the corporationMaturity id
  Future<bool?> deleteCorporationMaturity(String id) async {
    //api/corporation-maturity-dates/{id}
    final result =
        await HttpUtils.deleteRequest("/corporation-maturity-dates/$id");
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
    final result = await HttpUtils.putRequest("/corporation-maturity-dates/${corporationMaturity.id}", corporationMaturity);
    if (result.statusCode == 200) {
      return JsonMapper.deserialize<CorporationMaturity>(result.body);
    }
    return null;
  }
}
