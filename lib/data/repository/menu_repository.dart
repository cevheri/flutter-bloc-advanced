import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';

import '../models/menu.dart';

class MenuRepository {
  MenuRepository();

  Future<List<Menu>> getMenus() async {
    //final menusRequest = await HttpUtils.getRequest("/menus/current-user?page=0&size=200");
    var result = JsonMapper.deserialize<List<Menu>>(await rootBundle.loadString('assets/mock/menus.json'))!;
    return result;
  }
}
