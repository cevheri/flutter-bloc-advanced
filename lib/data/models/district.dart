import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class District {
  @JsonProperty(name: 'id')
  final int? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'code')
  final String? code;

  const District({this.id = 0, this.name = '', this.code = ''});

  @override
  String toString() {
    return 'District{id: $id, name: $name, code: $code}';
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is District && id == other.id && name == other.name && code == other.code;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ code.hashCode;
}
