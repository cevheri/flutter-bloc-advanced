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

  @JsonProperty(name: 'parentId')
  final int? parentId;

  @JsonProperty(name: 'level')
  final int level;

  const Menu({
    this.id = 1,
    this.name = '',
    this.description = '',
    this.url = '',
    this.icon = '',
    this.orderPriority = 0,
    this.active = false,
    this.parentId,
    this.level = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        url,
        icon,
        orderPriority,
        active,
        parentId,
        level,
      ];

  Menu copyWith({
    int? id,
    String? name,
    String? description,
    String? url,
    String? icon,
    int? orderPriority,
    bool? active,
    int? parentId,
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
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
    );
  }
}
