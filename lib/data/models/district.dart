import 'dart:convert';

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

  static District? fromJson(Map<String, dynamic> json) {
    var result = JsonMapper.fromMap<District>(json);
    if (result == null) {
      return null;
    }
    return result;
  }

  static District? fromJsonString(String json){
    var result = JsonMapper.deserialize<District>(jsonDecode(json));
    if (result == null) {
      return null;
    }
    return result;
  }

  Map<String, dynamic>? toJson() => JsonMapper.toMap(this);

  @override
  List<Object?> get props => [
        id,
        name,
        code,
      ];

  @override
  bool get stringify => true;
}
