import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class Task {
  @JsonProperty(name: 'id')
  final String? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'price')
  final int? price;

  Task({
    this.id = '',
    this.name = '',
    this.price = 0,
  });

  Task copyWith({
    String? id,
    String? name,
    int? price,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}
