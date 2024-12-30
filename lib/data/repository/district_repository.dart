import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';

import '../http_utils.dart';
import '../models/district.dart';

class DistrictRepository {
  static final _log = AppLogger.getLogger("DistrictRepository");

  DistrictRepository();

  final String _resource = "districts";

  /// Get all districts by city id
  Future<List<District?>> listByCity(String cityId) async {
    _log.debug("BEGIN:getDistrictsByCity repository start - cityId: {}", [cityId]);
    if (cityId.isEmpty) {
      throw BadRequestException("City id null");
    }
    final pathParams = cityId;
    final httpResponse = await HttpUtils.getRequest("/$_resource/cities", pathParams: pathParams);
    final response = District.fromJsonStringList(httpResponse.body);
    _log.debug("END:getDistrictsByCity successful - response list size: {}", [response.length]);
    return response;
  }

  Future<District?> create(District district) async {
    _log.debug("BEGIN:createDistrict repository start : {}", [district.toString()]);
    if (district.name == null || district.name!.isEmpty) {
      throw BadRequestException("District name null");
    }
    final httpResponse = await HttpUtils.postRequest("/$_resource", district);
    final response = District.fromJsonString(httpResponse.body);
    _log.debug("END:createDistrict successful");
    return response;
  }

  Future<List<District?>> list({int page = 0, int size = 10, List<String> sort = const ["id,desc"]}) async {
    _log.debug("BEGIN:getDistricts repository start - page: {}, size: {}, sort: {}", [page, size, sort]);
    final queryParams = {"page": page.toString(), "size": size.toString(), "sort": sort.join("&sort=")};
    final httpResponse = await HttpUtils.getRequest("/$_resource", queryParams: queryParams);
    final response = District.fromJsonStringList(httpResponse.body);
    _log.debug("END:getDistricts successful - response list size: {}", [response.length]);
    return response;
  }

  Future<District?> retrieve(String id) async {
    _log.debug("BEGIN:getDistrict repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException("District id null");
    }
    final pathParams = id;
    final httpResponse = await HttpUtils.getRequest("/$_resource", pathParams: pathParams);
    final response = District.fromJsonString(httpResponse.body);
    _log.debug("END:getDistrict successful - response.body: {}", [response.toString()]);
    return response;
  }

  Future<void> delete(String id) async {
    _log.debug("BEGIN:deleteDistrict repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException("District id null");
    }
    final pathParams = id;
    var httpResponse = await HttpUtils.deleteRequest("/$_resource", pathParams: pathParams);
    _log.debug("END:deleteDistrict successful - response status code: {}", [httpResponse.statusCode]);
  }
}
