import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

@jsonSerializable
class Status extends Equatable {
  @JsonProperty(name: 'id')
  final int? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'description')
  final String? description;

  @JsonProperty(name: 'orderPriority')
  final int? orderPriority;

  @JsonProperty(name: 'active')
  final bool? active;

  const Status({
    this.id,
    this.name,
    this.description,
    this.orderPriority,
    this.active,
  });

  Status copyWith({
    int? id,
    String? name,
    String? description,
    int? orderPriority,
    bool? active,
  }) {
    return Status(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      orderPriority: orderPriority ?? this.orderPriority,
      active: active ?? this.active,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        orderPriority,
        active,
      ];

  @override
  bool get stringify => true;
}
