import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
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
@jsonSerializable
class Menu extends Equatable {
  @JsonProperty(name: 'id')
  final String id;

  @JsonProperty(name: 'name')
  final String name;

  @JsonProperty(name: 'description')
  final String description;

  @JsonProperty(name: 'url')
  final String url;

  @JsonProperty(name: 'icon')
  final String icon;

  @JsonProperty(name: 'orderPriority')
  final int orderPriority;

  @JsonProperty(name: 'active')
  final bool active;

  @JsonProperty(name: 'parent')
  final Menu? parent;

  @JsonProperty(name: 'level')
  final int level;

  @JsonProperty(name: 'leaf')
  final bool? leaf;

  @JsonProperty(name: 'authorities')
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
    var result = JsonMapper.fromMap<Menu>(json);
    if (result == null) {
      return null;
    }
    return result;
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

  static Menu? fromJsonString(String json) {
    var result = JsonMapper.deserialize<Menu>(jsonDecode(json));
    if (result == null) {
      return null;
    }
    return result;
  }

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

  Map<String, dynamic>? toJson() => JsonMapper.toMap(this);

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
