import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

@jsonSerializable
class Authority extends Equatable {
  @JsonProperty(name: 'name')
  final String? name;

  const Authority({this.name});

  Authority copyWith({String? name}) {
    return Authority(name: name ?? this.name);
  }

  static Authority? fromJson(Map<String, dynamic> json) {
    if (json['name'] != null) {
      return Authority(name: json['name']);
    }
    return null;
  }

  static Authority? fromJsonString(String json) => fromJson(jsonDecode(json));

  static List<String?> fromJsonList(List<dynamic> json) =>
      json.map((value) => Authority.fromJson(value)?.name).toList();

  static List<String?> fromJsonStringList(String json) => fromJsonList(jsonDecode(json));

  Map<String, dynamic>? toJson() {
    return {'name': name};
  }

  @override
  List<Object?> get props => [name];

  @override
  String toString() {
    return 'Authority($name)';
  }
}
