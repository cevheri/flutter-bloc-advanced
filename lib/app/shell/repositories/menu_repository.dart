import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

import 'package:flutter_bloc_advance/app/shell/models/menu.dart';

class MenuRepository {
  static final _log = AppLogger.getLogger("MenuRepository");

  MenuRepository();

  Future<List<Menu>> list() async {
    _log.debug("BEGIN:getMenus repository start");
    final json = await rootBundle.loadString('assets/mock/menus.json');
    final result = Menu.fromJsonStringList(json);
    _log.debug("END:getMenus successful - response.body: {}", [result.toString()]);
    return result;
  }
}
