import 'dart:convert';

import 'package:equatable/equatable.dart';

class Authority extends Equatable {
  final String? name;

  const Authority({this.name});

  static Authority? fromJson(Map<String, dynamic> json) {
    if (json['name'] != null) {
      return Authority(name: json['name']);
    }
    return null;
  }

  static List<String?> fromJsonList(List<dynamic> json) =>
      json.map((value) => Authority.fromJson(value)?.name).toList();

  static List<String?> fromJsonStringList(String json) => fromJsonList(jsonDecode(json));

  @override
  List<Object?> get props => [name];

  @override
  String toString() {
    return 'Authority($name)';
  }
}
