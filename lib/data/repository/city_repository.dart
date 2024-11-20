import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';

import '../http_utils.dart';
import '../models/city.dart';

class CityRepository {
  CityRepository();

  final String _resource = "cities";

  Future<City?> createCity(City city) async {
    debugPrint("BEGIN:createCity repository start");
    if (city.name == null || city.name!.isEmpty) {
      throw BadRequestException("City name null");
    }
    final httpResponse = await HttpUtils.postRequest<City>("/$_resource", city);
    var response = City.fromJsonString(httpResponse.body);
    debugPrint("END:createCity successful");
    return response;
  }

  Future<List<City?>> getCities({int page = 0, int size = 10, List<String> sort = const ["id,desc"]}) async {
    debugPrint("BEGIN:getCities repository start");
    final httpResponse = await HttpUtils.getRequest("/$_resource?page=$page&size=$size&sort=${sort.join("&sort=")}");
    var response = City.fromJsonStringList(httpResponse.body);
    debugPrint("END:getCities successful");
    return response;
  }

  Future<City?> getCity(String id) async {
    debugPrint("BEGIN:getCity repository start");
    if (id.isEmpty) {
      throw BadRequestException("City id null");
    }
    final httpResponse = await HttpUtils.getRequest("/$_resource/$id");
    var response = City.fromJsonString(httpResponse.body);
    debugPrint("END:getCity successful");
    return response;
  }

  Future<void> deleteCity(String id) async {
    debugPrint("BEGIN:deleteCity repository start");
    if (id.isEmpty) {
      throw BadRequestException("City id null");
    }
    await HttpUtils.deleteRequest("/$_resource/$id");
    debugPrint("END:deleteCity successful");
  }
}
