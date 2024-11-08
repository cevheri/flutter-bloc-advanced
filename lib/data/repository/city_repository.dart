import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';
import '../models/city.dart';

class CityRepository {
  CityRepository();

  final String _resource = "cities";

  Future<List<City>> getCity() async {
    final result = await HttpUtils.getRequest("/$_resource?page=0&size=200");
    var defaultCityList = JsonMapper.deserialize<List<City>>(result)!;
    var sortWithNameResult = defaultCityList..sort((a, b) => a.id!.compareTo(b.id!));
    return sortWithNameResult;
  }
}
