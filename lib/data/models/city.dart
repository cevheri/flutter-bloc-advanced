import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

@jsonSerializable
class City extends Equatable {
  @JsonProperty(name: 'id')
  final String? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'plateCode')
  final String? plateCode;

  const City({this.id, this.name, this.plateCode});

  City copyWith({String? id, String? name, String? plateCode}) {
    return City(id: id ?? this.id, name: name ?? this.name, plateCode: plateCode ?? this.plateCode);
  }

  static City? fromJson(Map<String, dynamic> json) {
    return const City().copyWith(id: json['id'], name: json['name'], plateCode: json['plateCode']);
  }

  static City? fromJsonString(String json) {
    return fromJson(jsonDecode(json));
  }

  static List<City?> fromJsonList(List<dynamic> json) {
    return json.map((value) => City.fromJson(value)).toList();
  }

  static List<City?> fromJsonStringList(String json) {
    return fromJsonList(jsonDecode(json));
  }

  Map<String, dynamic>? toJson() {
    final Map<String, dynamic> json = {};
    if (id != null) {
      json['id'] = id;
    }
    if (name != null) {
      json['name'] = name;
    }
    if (plateCode != null) {
      json['plateCode'] = plateCode;
    }
    return json;
  }

  @override
  List<Object?> get props => [id, name, plateCode];

  @override
  bool get stringify => true;
}
