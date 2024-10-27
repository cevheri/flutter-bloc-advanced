import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';

import '../models/menu.dart';

class MenuRepository {
  MenuRepository();

  Future<List<Menu>> getMenus() async {
    return JsonMapper.deserialize<List<Menu>>(await rootBundle.loadString('assets/mock/menus.json'))!;
  }
}
