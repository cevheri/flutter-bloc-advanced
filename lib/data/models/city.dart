import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

@jsonSerializable
class City extends Equatable {
  @JsonProperty(name: 'id')
  final int? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'plateCode')
  final String? plateCode;

  const City({
    this.id,
    this.name,
    this.plateCode,
  });

  City copyWith({
    int? id,
    String? name,
    String? plateCode,
  }) {
    return City(
      id: id ?? this.id,
      name: name ?? this.name,
      plateCode: plateCode ?? this.plateCode,
    );
  }

  static City? fromJson(Map<String, dynamic> json) {
    var result = JsonMapper.fromMap<City>(json);
    if (result == null) {
      return null;
    }
    return result;
  }

  static City? fromJsonString(String json) {
    var result = JsonMapper.deserialize<City>(jsonDecode(json));
    if (result == null) {
      return null;
    }
    return result;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        plateCode,
      ];

  @override
  bool get stringify => true;
}
