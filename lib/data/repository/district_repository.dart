import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';
import '../models/district.dart';

class DistrictRepository {
  DistrictRepository();

  Future<List<District>> getDistrict(cityId) async {
    final result = await HttpUtils.getRequest("/districts/cities/$cityId");
    return JsonMapper.deserialize<List<District>>(result)!;
  }
}
