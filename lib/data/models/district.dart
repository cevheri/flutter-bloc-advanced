import 'dart:convert';

import 'package:equatable/equatable.dart';

class District extends Equatable {
  final String? id;
  final String? name;
  final String? code;

  const District({this.id, this.name, this.code});

  District copyWith({String? id, String? name, String? code}) {
    return District(id: id ?? this.id, name: name ?? this.name, code: code ?? this.code);
  }

  static District? fromJson(Map<String, dynamic> json) {
    return const District().copyWith(id: json['id'], name: json['name'], code: json['code']);
  }

  static District? fromJsonString(String json) => fromJson(jsonDecode(json));

  static List<District?> fromJsonList(List<dynamic> json) => json.map((value) => District.fromJson(value)).toList();

  static List<District?> fromJsonStringList(String json) => fromJsonList(jsonDecode(json));

  Map<String, dynamic>? toJson() {
    Map<String, dynamic> json = {};
    if (id != null) {
      json['id'] = id;
    }
    if (name != null) {
      json['name'] = name;
    }
    if (code != null) {
      json['code'] = code;
    }
    return json;
  }

  @override
  List<Object?> get props => [id, name, code];

  @override
  bool get stringify => true;
}
