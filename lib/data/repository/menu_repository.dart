import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';

import '../models/menu.dart';

class MenuRepository {
  static final _log = AppLogger.getLogger("MenuRepository");

  MenuRepository();

  Future<List<Menu>> getMenus() async {
    _log.debug("BEGIN:getMenus repository start");
    final result = JsonMapper.deserialize<List<Menu>>(await rootBundle.loadString('assets/mock/menus.json'))!;
    _log.debug("END:getMenus successful - response.body: {}", [result.toString()]);
    return result;
  }
}
