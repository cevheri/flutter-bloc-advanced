import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class Menu extends Equatable {

  @JsonProperty(name: 'id')
  final int id;

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

  // salesPersonCode and salesPersonName

  const Menu({
    this.id = 0,
    this.name = '',
    this.description = '',
    this.url = '',
    this.icon = '',
    this.orderPriority = 0,
    this.active = false,
    this.parent,
    this.level = 0,
  });

  Menu copyWith({
    int? id,
    String? name,
    String? description,
    String? url,
    String? icon,
    int? orderPriority,
    bool? active,
    Menu? parent,
    int? level,
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
    );
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
      ];

  @override
  bool get stringify => true;
}
