import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';

import '../http_utils.dart';
import '../models/district.dart';

class DistrictRepository {
  static final _log = AppLogger.getLogger("DistrictRepository");

  DistrictRepository();

  final String _resource = "districts";

  /// Get all districts by city id
  Future<List<District?>> getDistrictsByCity(String cityId) async {
    _log.debug("BEGIN:getDistrictsByCity repository start - cityId: {}", [cityId]);
    if (cityId.isEmpty) {
      throw BadRequestException("City id null");
    }
    final httpResponse = await HttpUtils.getRequest("/$_resource/cities/$cityId");
    final response = District.fromJsonStringList(httpResponse.body);
    _log.debug("END:getDistrictsByCity successful - response list size: {}", [response.length]);
    return response;
  }

  Future<District?> createDistrict(District district) async {
    _log.debug("BEGIN:createDistrict repository start : {}", [district.toString()]);
    if (district.name == null || district.name!.isEmpty) {
      throw BadRequestException("District name null");
    }
    final httpResponse = await HttpUtils.postRequest("/$_resource", district);
    final response = District.fromJsonString(httpResponse.body);
    _log.debug("END:createDistrict successful");
    return response;
  }

  Future<List<District?>> getDistricts({int page = 0, int size = 10, List<String> sort = const ["id,desc"]}) async {
    _log.debug("BEGIN:getDistricts repository start - page: {}, size: {}, sort: {}", [page, size, sort]);
    final httpResponse = await HttpUtils.getRequest("/$_resource?page=$page&size=$size&sort=${sort.join("&sort=")}");
    final response = District.fromJsonStringList(httpResponse.body);
    _log.debug("END:getDistricts successful - response list size: {}", [response.length]);
    return response;
  }

  Future<District?> getDistrict(String id) async {
    _log.debug("BEGIN:getDistrict repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException("District id null");
    }
    final httpResponse = await HttpUtils.getRequest("/$_resource/$id");
    final response = District.fromJsonString(httpResponse.body);
    _log.debug("END:getDistrict successful - response.body: {}", [response.toString()]);
    return response;
  }

  Future<void> deleteDistrict(String id) async {
    _log.debug("BEGIN:deleteDistrict repository start - id: {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException("District id null");
    }
    var httpResponse = await HttpUtils.deleteRequest("/$_resource/$id");
    _log.debug("END:deleteDistrict successful - response status code: {}", [httpResponse.statusCode]);
  }
}
