import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

@jsonSerializable
class JWTToken extends Equatable {
  @JsonProperty(name: 'id_token')
  final String? idToken;

  const JWTToken({this.idToken});

  JWTToken copyWith({String? idToken}) {
    return JWTToken(idToken: idToken ?? this.idToken);
  }

  static JWTToken? fromJson(Map<String, dynamic> json) {
    var result = JsonMapper.fromMap<JWTToken>(json);
    if (result == null) {
      return null;
    }
    return result;
  }

  static JWTToken? fromJsonString(String json) {
    var result = JsonMapper.deserialize<JWTToken>(jsonDecode(json));
    if (result == null) {
      return null;
    }
    return result;
  }

  Map<String, dynamic>? toJson() => JsonMapper.toMap(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is JWTToken && runtimeType == other.runtimeType && idToken == other.idToken;

  @override
  int get hashCode => idToken.hashCode;

  @override
  List<Object?> get props => [idToken];

  @override
  bool get stringify => true;
}
