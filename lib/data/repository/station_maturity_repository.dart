import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';

import '../http_utils.dart';
import '../models/station_maturity.dart';

/// stationMaturity repository
///
/// This class is responsible for all the stationMaturity related operations
/// list, create, update, delete etc.
class StationMaturityRepository {
  /// Retrieve all stationMaturities method that retrieves all the stationMaturitys
  Future<List<StationMaturity>> getStationMaturitys() async {
    final stationMaturitysRequest =
        await HttpUtils.get("/stationMaturitys");
    return JsonMapper.deserialize<List<StationMaturity>>(
        stationMaturitysRequest)!;
  }

  /// Retrieve stationMaturity method that retrieves a stationMaturity by id
  ///
  /// @param id the stationMaturity id
  Future<List<StationMaturity>> getStationMaturity(String id) async {
    //final result = await HttpUtils.getRequest("/station-maturity-prices/stations/$id?page=0&size=10");
    var defaultCityList = JsonMapper.deserialize<List<StationMaturity>>(await rootBundle.loadString('mock/subcompany_maturity.json'))!;
    var sortWithNameResult = defaultCityList
      ..sort((a, b) => a.id!.compareTo(b.id!));
    return sortWithNameResult;
  }

  /// Create stationMaturity method that creates a new stationMaturity
  ///
  /// @param stationMaturity the stationMaturity object
  Future<StationMaturity?> createStationMaturity(
      StationMaturity stationMaturity) async {
    final saveRequest = await HttpUtils.postRequest<StationMaturity>(
        "/station-maturity-prices", stationMaturity);
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
        ? JsonMapper.deserialize<StationMaturity>(saveRequest.body)
        : null;
  }

  /// Find stationMaturity method that findStationMaturity a stationMaturity
  Future<List<StationMaturity>> findStationMaturity(
    int rangeStart,
    int rangeEnd,
  ) async {


    final getRequest = await HttpUtils.get(
        "/stationMaturitys?page=${rangeStart.toString()}&size=${rangeEnd.toString()}");

    return JsonMapper.deserialize<List<StationMaturity>>(getRequest)!;
  }

  /// Find stationMaturity method that findStationMaturityByAuthorities a stationMaturity
  Future<List<StationMaturity>> findStationMaturityByAuthorities(
    int rangeStart,
    int rangeEnd,
    String authorities,
  ) async {
    final stationMaturityRequest = await HttpUtils.get(
        "/stationMaturitys/authorities/$authorities?page=${rangeStart.toString()}&size=${rangeEnd.toString()}");
    var result =
        JsonMapper.deserialize<List<StationMaturity>>(stationMaturityRequest)!;
    return result;
  }

  /// Find stationMaturity method that findStationMaturityByName a stationMaturity
  Future<List<StationMaturity>> findStationMaturityByName(
    int rangeStart,
    int rangeEnd,
    String name,
  ) async {
    final stationMaturityRequest = await HttpUtils.get(
        "/stationMaturitys/filter/$name?page=${rangeStart.toString()}&size=${rangeEnd.toString()}");
    var result =
        JsonMapper.deserialize<List<StationMaturity>>(stationMaturityRequest)!;
    return result;
  }

  /// Delete stationMaturity method that deletes a stationMaturity by id
  ///
  /// @param id the stationMaturity id
  Future<bool?> deleteStationMaturity(String id) async {
    final result =
        await HttpUtils.deleteRequest("/station-maturity-prices/$id");
    if (result.statusCode == 204) {
      return true;
    }
    return false;
  }

  /// Update stationMaturity method that updates a stationMaturity
  ///
  /// @param stationMaturity the stationMaturity object
  Future<StationMaturity?> updateStationMaturity(
      StationMaturity stationMaturity) async {
    final result = await HttpUtils.putRequest("/station-maturity-prices/${stationMaturity.id}", stationMaturity);
    if (result.statusCode == 200) {
      return JsonMapper.deserialize<StationMaturity>(result.body);
    }
    return null;
  }
}
