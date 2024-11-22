import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';

import '../http_utils.dart';
import '../models/city.dart';

class CityRepository {
  static final _log = AppLogger.getLogger("CityRepository");
  CityRepository();

  final String _resource = "cities";

  Future<City?> createCity(City city) async {
    _log.debug("BEGIN:createCity repository start : {}", [city.toString()]);
    if (city.name == null || city.name!.isEmpty) {
      throw BadRequestException("City name null");
    }
    final httpResponse = await HttpUtils.postRequest<City>("/$_resource", city);
    var response = City.fromJsonString(httpResponse.body);
    _log.debug("END:createCity successful");
    return response;
  }

  Future<List<City?>> getCities({int page = 0, int size = 10, List<String> sort = const ["id,desc"]}) async {
    _log.debug("BEGIN:getCities repository start - page: {}, size: {}, sort: {}", [page, size, sort]);
    final httpResponse = await HttpUtils.getRequest("/$_resource?page=$page&size=$size&sort=${sort.join("&sort=")}");
    var response = City.fromJsonStringList(httpResponse.body);
    _log.debug("END:getCities successful - response list size: {}", [response.length]);
    return response;
  }

  Future<City?> getCity(String id) async {
    _log.debug("BEGIN:getCity repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException("City id null");
    }
    final httpResponse = await HttpUtils.getRequest("/$_resource/$id");
    var response = City.fromJsonString(httpResponse.body);
    _log.debug("END:getCity successful - response.body: {}", [response.toString()]);
    return response;
  }

  Future<void> deleteCity(String id) async {
    _log.debug("BEGIN:deleteCity repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException("City id null");
    }
    final httpResponse = await HttpUtils.deleteRequest("/$_resource/$id");
    _log.debug("END:deleteCity successful - response status code: {}", [httpResponse.statusCode]);
  }
}
