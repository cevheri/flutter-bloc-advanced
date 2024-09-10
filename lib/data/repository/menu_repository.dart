import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';

import '../../configuration/environment.dart';
import '../http_utils.dart';
import '../models/menu.dart';

class MenuRepository {
  MenuRepository();

  //TODO if (ProfileConstants.isProduction) {}
  Future<List<Menu>> getMenus() async {
    if (ProfileConstants.isProduction) {
      final menusRequest = await HttpUtils.getRequest("/menus/current-user?page=0&size=200");
      return JsonMapper.deserialize<List<Menu>>(menusRequest)!;
    } else {
      return JsonMapper.deserialize<List<Menu>>(await rootBundle.loadString('assets/mock/menus.json'))!;
    }
  }
}
