import 'dart:developer';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';

import '../http_utils.dart';
import '../models/station.dart';

/// station repository
///
/// This class is responsible for all the station related operations
/// list, create, update, delete etc.
class StationRepository {
  /// Retrieve all stations method that retrieves all the stations
  Future<List<Station>> getStations() async {
    final stationsRequest = await HttpUtils.getRequest("/stations");
    return JsonMapper.deserialize<List<Station>>(stationsRequest)!;
  }

  /// Retrieve station method that retrieves a station by id
  ///
  /// @param id the station id
  Future<Station> getStation(String id) async {
    final stationRequest = await HttpUtils.getRequest("/stations/$id");
    return JsonMapper.deserialize<Station>(stationRequest)!;
  }

  /// Create station method that creates a new station
  ///
  /// @param station the station object
  Future<Station?> createStation(Station station) async {
    final saveRequest =
        await HttpUtils.postRequest<Station>("/stations", station);
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
        ? JsonMapper.deserialize<Station>(saveRequest.body)
        : null;
  }

  /// List station method that lists all the stations
  ///
  /// @param station the station object
  Future<List<Station>> listStationWithCityId(String cityId) async {
    final saveRequest = await HttpUtils.getRequest(
        "/stations?cityId.equals=$cityId&page=0&size=100");
    return JsonMapper.deserialize<List<Station>>(saveRequest)!;
  }

  /// List station method that lists all the stations
  ///
  /// @param station the station object
  Future<List<Station>> listStation(
    String? cityId,
    String? corporationId,
  ) async {
    if (cityId == "0" && corporationId == "0") {
      // final saveRequest = await HttpUtils.getRequest("/stations?page=0&size=100");
      return JsonMapper.deserialize<List<Station>>(
          await rootBundle.loadString('mock/subcompany.json'))!;
    } else if (cityId != "0" && corporationId == "0") {
      //final saveRequest = await HttpUtils.getRequest("/stations?cityId.equals=$cityId&page=0&size=100");
      //return JsonMapper.deserialize<List<Station>>(saveRequest)!;
      return JsonMapper.deserialize<List<Station>>(
          await rootBundle.loadString('mock/subcompany.json'))!;
    } else if (cityId == "0" && corporationId != "0") {
      //final saveRequest = await HttpUtils.getRequest( "/stations?corporationId.equals=$corporationId&page=0&size=100");
      //return JsonMapper.deserialize<List<Station>>(saveRequest)!;
      return JsonMapper.deserialize<List<Station>>(
          await rootBundle.loadString('mock/subcompany.json'))!;
    } else {
      //final saveRequest = await HttpUtils.getRequest("/stations?cityId.equals=$cityId&corporationId.equals=$corporationId&page=0&size=100");
      //return JsonMapper.deserialize<List<Station>>(saveRequest)!;
      return JsonMapper.deserialize<List<Station>>(
          await rootBundle.loadString('mock/subcompany.json'))!;
    }
  }

  /// Update station method that updates a station
  ///
  /// @param station the station object
  Future<Station?> updateStation(Station station) async {
    final saveRequest = await HttpUtils.putRequest<Station>(
        "/stations/${station.id.toString()}", station);
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
        ? JsonMapper.deserialize<Station>(saveRequest.body)
        : null;
  }

  /// ListStation with corporationId method that lists all the stations
  ///
  /// @param station the station object
  Future<List<Station>> listStationWithCorporationId(
      String corporationId) async {
    final saveRequest = await HttpUtils.getRequest(
        "/stations?corporationId.equals=$corporationId&page=0&size=100");
    return JsonMapper.deserialize<List<Station>>(saveRequest)!;
  }
}
