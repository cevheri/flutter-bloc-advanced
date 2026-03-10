import 'dart:convert';

import 'package:equatable/equatable.dart';

/// menu object
/// example:
/// id	name	description	url	icon	order_priority	active	parent_id	level
// 1	home	home	/	icon	0	1		0
// 2	account	account	branch	icon	4	1	1	1
// 3	logout	logout	/logout	icon	1	1	2	2
// 4	login	login	/login	icon	2	1	2	2
// 5	settings	settings	branch	icon	3	1	1	1

/// ApplicationUser model that represents the user entity in this application.
///
/// this is an immutable class that extends [Equatable] so that it can be compared
class Menu extends Equatable {
  final String id;
  final String name;
  final String description;
  final String url;
  final String icon;
  final int orderPriority;
  final bool active;
  final Menu? parent;
  final int level;
  final bool? leaf;
  final List<String>? authorities;

  const Menu({
    this.id = '',
    this.name = '',
    this.description = '',
    this.url = '',
    this.icon = '',
    this.orderPriority = 0,
    this.active = false,
    this.parent,
    this.level = 0,
    this.leaf = false,
    this.authorities = const [],
  });

  Menu copyWith({
    String? id,
    String? name,
    String? description,
    String? url,
    String? icon,
    int? orderPriority,
    bool? active,
    Menu? parent,
    int? level,
    bool? leaf,
    List<String>? authorities,
  }) {
    return Menu(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      icon: icon ?? this.icon,
      orderPriority: orderPriority ?? this.orderPriority,
      active: active ?? this.active,
      parent: parent ?? this.parent,
      level: level ?? this.level,
      leaf: leaf ?? this.leaf,
      authorities: authorities ?? this.authorities,
    );
  }

  static Menu? fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      icon: json['icon'] ?? '',
      orderPriority: json['orderPriority'] ?? 0,
      active: json['active'] ?? false,
      parent: json['parent'] != null ? Menu.fromJson(json['parent']) : null,
      level: json['level'] ?? 0,
      leaf: json['leaf'],
      authorities: json['authorities'] != null ? List<String>.from(json['authorities']) : null,
    );
  }

  static List<Menu> fromJsonList(List<dynamic> json) {
    List<Menu> result = [];
    for (var item in json) {
      var menu = Menu.fromJson(item as Map<String, dynamic>);
      if (menu != null) {
        result.add(menu);
      }
    }
    return result;
  }

  static Menu? fromJsonString(String json) => fromJson(jsonDecode(json));

  static List<Menu> fromJsonStringList(String json) {
    List<Menu> result = [];
    var jsonList = jsonDecode(json) as List<dynamic>;
    for (var item in jsonList) {
      var menu = Menu.fromJson(item as Map<String, dynamic>);
      if (menu != null) {
        result.add(menu);
      }
    }
    return result;
  }

  Map<String, dynamic>? toJson() {
    final Map<String, dynamic> json = {};
    if (id.isNotEmpty) json['id'] = id;
    if (name.isNotEmpty) json['name'] = name;
    if (description.isNotEmpty) json['description'] = description;
    if (url.isNotEmpty) json['url'] = url;
    if (icon.isNotEmpty) json['icon'] = icon;
    if (orderPriority != 0) json['orderPriority'] = orderPriority;
    json['active'] = active;
    if (parent != null) json['parent'] = parent!.toJson();
    if (level != 0) json['level'] = level;
    if (leaf != null) json['leaf'] = leaf;
    if (authorities != null && authorities!.isNotEmpty) json['authorities'] = authorities;
    return json;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    url,
    icon,
    orderPriority,
    active,
    parent,
    level,
    leaf,
    authorities,
  ];

  @override
  bool get stringify => true;
}
