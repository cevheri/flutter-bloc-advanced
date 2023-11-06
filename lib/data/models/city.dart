import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class City {
  @JsonProperty(name: 'id')
  final int? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'plateCode')
  final String? plateCode;

  const City({this.id = 0, this.name = '', this.plateCode = ''});

  @override
  String toString() {
    return 'City{id: $id, name: $name, plateCode: $plateCode}';
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is City && id == other.id && name == other.name && plateCode == other.plateCode;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ plateCode.hashCode;
}
