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
    if (json['name'] != null) {
      return Authorities(name: json['name']);
    }
    return null;
  }

  static Authorities? fromJsonString(String json) {
    return fromJson(jsonDecode(json));
  }

  Map<String, dynamic>? toJson() {
    return {
      'name': name,
    };
  }

  @override
  List<Object?> get props => [
        name,
      ];

  @override
  bool get stringify => true;
}
