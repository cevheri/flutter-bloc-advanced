import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

/// ApplicationUser model that represents the user entity in this application.
///
/// this is an immutable class that extends [Equatable] so that it can be compared
@jsonSerializable
class SalesPerson extends Equatable {
  @JsonProperty(name: 'id')
  final String? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'code')
  final String? code;

  @JsonProperty(name: 'active')
  final bool? active;

  const SalesPerson({
    this.id,
    this.name,
    this.code,
    this.active,
  });

  SalesPerson copyWith({
    String? id,
    String? name,
    String? code,
    bool? active,
  }) {
    return SalesPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      active: active ?? this.active,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    active,
  ];

  @override
  bool get stringify => true;
}