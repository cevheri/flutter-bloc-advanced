import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../models/menu.dart';

class MenuRepository {
  MenuRepository();

  Future<List<Menu>> getMenus() async {
    var obj = [
      {
        "id": 2,
        "name": "account",
        "description": "account",
        "url": "/account",
        "icon": "account",
        "orderPriority": 1,
        "active": true,
        "parent": {
          "id": 1,
          "name": "home",
          "description": "home",
          "url": "/",
          "icon": "icon",
          "orderPriority": 0,
          "active": true,
          "level": 0
        },
        "level": 1
      },
      {
        "id": 3,
        "name": "logout",
        "description": "logout",
        "url": "/logout",
        "icon": "logout",
        "orderPriority": 2,
        "active": true,
        "parent": {
          "id": 2,
          "name": "account",
          "description": "account",
          "url": "/account",
          "icon": "account",
          "orderPriority": 1,
          "active": true,
          "level": 1
        },
        "level": 2
      },
      {
        "id": 5,
        "name": "settings",
        "description": "settings",
        "url": "/settings",
        "icon": "cog-outline",
        "orderPriority": 6,
        "active": true,
        "parent": {
          "id": 1,
          "name": "home",
          "description": "home",
          "url": "/",
          "icon": "icon",
          "orderPriority": 0,
          "active": true,
          "level": 0
        },
        "level": 1
      },
      {
        "id": 25,
        "name": "language",
        "description": "language",
        "url": "/language",
        "icon": "web",
        "orderPriority": 1,
        "active": true,
        "parent": {
          "id": 1,
          "name": "home",
          "description": "home",
          "url": "/",
          "icon": "icon",
          "orderPriority": 0,
          "active": true,
          "level": 0
        },
        "level": 1
      },
      {
        "id": 8,
        "name": "register",
        "description": "register",
        "url": "/register",
        "icon": "account-tie",
        "orderPriority": 2,
        "active": true,
        "parent": {
          "id": 1,
          "name": "home",
          "description": "home",
          "url": "/",
          "icon": "icon",
          "orderPriority": 0,
          "active": true,
          "level": 0
        },
        "level": 1
      },      {
        "id": 20,
        "name": " New account",
        "description": "New account",
        "url": "/account",
        "icon": "account-tie",
        "orderPriority": 2,
        "active": true,
        "parent": {
          "id": 1,
          "name": "home",
          "description": "home",
          "url": "/",
          "icon": "icon",
          "orderPriority": 0,
          "active": true,
          "level": 0
        },
        "level": 1
      },
      {
        "id": 9,
        "name": "createOffer",
        "description": "createOffer",
        "url": "/salesPerson/createOffer",
        "icon": "account-multiple-plus-outline",
        "orderPriority": 1,
        "active": true,
        "parent": {
          "id": 8,
          "name": "salesPerson",
          "description": "salesPerson",
          "url": "/salesPerson",
          "icon": "account-tie",
          "orderPriority": 2,
          "active": true,
          "level": 1
        },
        "level": 2
      },
      {
        "id": 10,
        "name": "editOffer",
        "description": "editOffer",
        "url": "/salesPerson/editOffer",
        "icon": "account-edit-outline",
        "orderPriority": 2,
        "active": true,
        "parent": {
          "id": 8,
          "name": "salesPerson",
          "description": "salesPerson",
          "url": "/salesPerson",
          "icon": "account-tie",
          "orderPriority": 2,
          "active": true,
          "level": 1
        },
        "level": 2
      },
      {
        "id": 11,
        "name": "customer",
        "description": "customer",
        "url": "/customer",
        "icon": "account-group-outline",
        "orderPriority": 3,
        "active": true,
        "parent": {
          "id": 1,
          "name": "home",
          "description": "home",
          "url": "/",
          "icon": "icon",
          "orderPriority": 0,
          "active": true,
          "level": 0
        },
        "level": 1
      },
      {
        "id": 14,
        "name": "dashboard",
        "description": "dashboard",
        "url": "/dashboard",
        "icon": "finance",
        "orderPriority": 5,
        "active": true,
        "parent": {
          "id": 1,
          "name": "home",
          "description": "home",
          "url": "/",
          "icon": "icon",
          "orderPriority": 0,
          "active": true,
          "level": 0
        },
        "level": 1
      },
      {
        "id": 20,
        "name": "tasks",
        "description": "tasks",
        "url": "/tasks",
        "icon": "file-chart",
        "orderPriority": 4,
        "active": true,
        "parent": {
          "id": 1,
          "name": "home",
          "description": "home",
          "url": "/",
          "icon": "icon",
          "orderPriority": 0,
          "active": true,
          "level": 0
        },
        "level": 1
      },
      {
        "id": 22,
        "name": "login",
        "description": "login",
        "url": "/login",
        "icon": "information",
        "orderPriority": 1,
        "active": true,
        "parent": {
          "id": 2,
          "name": "account",
          "description": "account",
          "url": "/account",
          "icon": "account",
          "orderPriority": 1,
          "active": true,
          "level": 1
        },
        "level": 2
      }
    ];
   List<Menu> menus = JsonMapper.deserialize<List<Menu>>(obj)!;

    return menus;
  }
}
