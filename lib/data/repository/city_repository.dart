import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';
import '../models/city.dart';

class CityRepository {
  CityRepository();

  Future<List<City>> getCity() async {
    final result = await HttpUtils.get("/cities?page=0&size=200");
    var defaultCityList = JsonMapper.deserialize<List<City>>(result)!;
    var sortWithNameResult = defaultCityList
      ..sort((a, b) => a.id!.compareTo(b.id!));
    return sortWithNameResult;
  }
}
