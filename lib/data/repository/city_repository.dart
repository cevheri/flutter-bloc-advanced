import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';

import '../http_utils.dart';
import '../models/city.dart';

class CityRepository {
  static final _log = AppLogger.getLogger("CityRepository");

  CityRepository();

  final String _resource = "cities";

  Future<City?> create(City city) async {
    _log.debug("BEGIN:createCity repository start : {}", [city.toString()]);
    if (city.name == null || city.name!.isEmpty) {
      throw BadRequestException("City name null");
    }
    final httpResponse = await HttpUtils.postRequest<City>("/$_resource", city);
    var response = City.fromJsonString(httpResponse.body);
    _log.debug("END:createCity successful");
    return response;
  }

  Future<List<City?>> list({int page = 0, int size = 10, List<String> sort = const ["id,desc"]}) async {
    _log.debug("BEGIN:getCities repository start - page: {}, size: {}, sort: {}", [page, size, sort]);
    final queryParams = {"page": page.toString(), "size": size.toString(), "sort": sort.join("&sort=")};
    final httpResponse = await HttpUtils.getRequest("/$_resource", queryParams: queryParams);
    var response = City.fromJsonStringList(httpResponse.body);
    _log.debug("END:getCities successful - response list size: {}", [response.length]);
    return response;
  }

  Future<City?> retrieve(String id) async {
    _log.debug("BEGIN:getCity repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException("City id null");
    }
    final pathParams = id;
    final httpResponse = await HttpUtils.getRequest("/$_resource", pathParams: pathParams);
    var response = City.fromJsonString(httpResponse.body);
    _log.debug("END:getCity successful - response.body: {}", [response.toString()]);
    return response;
  }

  Future<void> delete(String id) async {
    _log.debug("BEGIN:deleteCity repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException("City id null");
    }
    final pathParams = id;
    final httpResponse = await HttpUtils.deleteRequest("/$_resource", pathParams: pathParams);
    _log.debug("END:deleteCity successful - response status code: {}", [httpResponse.statusCode]);
  }
}
