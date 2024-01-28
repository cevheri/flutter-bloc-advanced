import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

@jsonSerializable
class District extends Equatable {
  @JsonProperty(name: 'id')
  final String? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'code')
  final String? code;

  const District({
    this.id,
    this.name,
    this.code,
  });


  District copyWith({
    String? id,
    String? name,
    String? code,
  }) {
    return District(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    code,
  ];

  @override
  bool get stringify => true;
}
