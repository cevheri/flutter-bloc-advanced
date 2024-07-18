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
  final String _path = "/stations";

  /// Retrieve all stations method that retrieves all the stations
  Future<List<Station>> getStations() async {
    final response = await HttpUtils.get(_path);
    return JsonMapper.deserialize<List<Station>>(response)!;
  }

  /// Retrieve station method that retrieves a station by id
  ///
  /// @param id the station id
  Future<Station> getStation(String id) async {
    final stationRequest = await HttpUtils.get(_path, "/$id");
    return JsonMapper.deserialize<Station>(stationRequest)!;
  }

  /// Create station method that creates a new station
  ///
  /// @param station the station object
  Future<Station?> createStation(Station station) async {
    final response = await HttpUtils.postRequest<Station>(_path, station);
    String? result;

    if (response.statusCode != 201) {
      if (response.headers[HttpUtils.errorHeader] != null) {
        result = response.headers[HttpUtils.errorHeader];
      } else {
        result = HttpUtils.errorServerKey;
      }
    } else {
      result = HttpUtils.successResult;
    }

    return result == HttpUtils.successResult ? JsonMapper.deserialize<Station>(response.body) : null;
  }

  /// List station method that lists all the stations
  ///
  /// @param station the station object
  Future<List<Station>> listStationWithCityId(String cityId) async {
    final response = await HttpUtils.get(_path, "?cityId.equals=$cityId&page=0&size=10");
    return JsonMapper.deserialize<List<Station>>(response)!;
  }

  /// List station method that lists all the stations
  ///
  /// @param station the station object
  Future<List<Station>> listStation(
    String? cityId,
    String? corporationId,
  ) async {
    final response = await HttpUtils.get(_path, "?cityId.equals=$cityId&corporationId.equals=$corporationId&page=0&size=10");
    return JsonMapper.deserialize<List<Station>>(response)!;

  }

  /// Update station method that updates a station
  ///
  /// @param station the station object
  Future<Station?> updateStation(Station station) async {
    final saveRequest = await HttpUtils.putRequest<Station>("$_path/${station.id.toString()}", station);
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

    return result == HttpUtils.successResult ? JsonMapper.deserialize<Station>(saveRequest.body) : null;
  }

  /// ListStation with corporationId method that lists all the stations
  ///
  /// @param station the station object
  Future<List<Station>> listStationWithCorporationId(String corporationId) async {
    final response = await HttpUtils.get(_path, "?corporationId.equals=$corporationId&page=0&size=10");
    return JsonMapper.deserialize<List<Station>>(response)!;
  }
}
