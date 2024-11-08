import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';
import '../models/district.dart';

class DistrictRepository {
  DistrictRepository();

  final String _resource = "districts";

  Future<List<District>> getDistrict(cityId) async {
    final result = await HttpUtils.getRequest("/$_resource/cities/$cityId");
    return JsonMapper.deserialize<List<District>>(result)!;
  }
}
