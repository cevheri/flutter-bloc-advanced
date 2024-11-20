import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';

import '../http_utils.dart';
import '../models/district.dart';

class DistrictRepository {
  DistrictRepository();

  final String _resource = "districts";

  /// Get all districts by city id
  Future<List<District?>> getDistrictsByCity(String cityId) async {
    debugPrint("BEGIN:getDistrictsByCity repository start");
    if(cityId.isEmpty){
      throw BadRequestException("City id null");
    }
    final httpResponse = await HttpUtils.getRequest("/$_resource/cities/$cityId");
    final response = District.fromJsonStringList(httpResponse.body);
    debugPrint("END:getDistrictsByCity successful");
    return response;
  }

  Future<District?> createDistrict(District district) async {
    debugPrint("BEGIN:createDistrict repository start");
    if (district.name == null || district.name!.isEmpty) {
      throw BadRequestException("District name null");
    }
    final httpResponse = await HttpUtils.postRequest("/$_resource", district);
    final response = District.fromJsonString(httpResponse.body);
    debugPrint("END:createDistrict successful");
    return response;
  }

  Future<List<District?>> getDistricts({int page = 0, int size = 10, List<String> sort = const ["id,desc"]}) async {
    debugPrint("BEGIN:getDistricts repository start");
    final httpResponse = await HttpUtils.getRequest("/$_resource?page=$page&size=$size&sort=${sort.join("&sort=")}");
    final response = District.fromJsonStringList(httpResponse.body);
    debugPrint("END:getDistricts successful");
    return response;
  }

  Future<District?> getDistrict(String id) async {
    debugPrint("BEGIN:getDistrict repository start");
    if (id.isEmpty) {
      throw BadRequestException("District id null");
    }
    final httpResponse = await HttpUtils.getRequest("/$_resource/$id");
    final response = District.fromJsonString(httpResponse.body);
    debugPrint("END:getDistrict successful");
    return response;
  }

  Future<void> deleteDistrict(String id) async {
    debugPrint("BEGIN:deleteDistrict repository start");
    if (id.isEmpty) {
      throw BadRequestException("District id null");
    }
    await HttpUtils.deleteRequest("/$_resource/$id");
    debugPrint("END:deleteDistrict successful");
  }
}
