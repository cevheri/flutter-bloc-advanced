import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/data/models/district.dart';

import 'city.dart';

@jsonSerializable
class Maturity extends Equatable {
  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'type')
  final int? type;

  const Maturity({
    this.name,
    this.type,
  });

  Maturity copyWith({
    String? name,
    int? type,
  }) {
    return Maturity(
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
        name,
        type,
      ];

  @override
  bool get stringify => true;
}

