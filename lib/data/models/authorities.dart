import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

@jsonSerializable
class Authorities extends Equatable {
  @JsonProperty(name: 'name')
  final String? name;

  const Authorities({
    this.name,
  });

  Authorities copyWith({
    String? name,
  }) {
    return Authorities(
      name: name ?? this.name,
    );
  }

  static Authorities? fromJson(Map<String, dynamic> json) {
    var result = JsonMapper.fromMap<Authorities>(json);
    if (result == null) {
      return null;
    }
    return result;
  }

  static Authorities? fromJsonString(String json){
    var result = JsonMapper.deserialize<Authorities>(jsonDecode(json));
    if (result == null) {
      return null;
    }
    return result;
  }

  @override
  List<Object?> get props => [
        name,
      ];

  @override
  bool get stringify => true;
}
