import 'dart:convert';

import 'package:equatable/equatable.dart';

class JWTToken extends Equatable {
  final String? idToken;

  const JWTToken({this.idToken});

  JWTToken copyWith({String? idToken}) {
    return JWTToken(idToken: idToken ?? this.idToken);
  }

  static JWTToken? fromJson(Map<String, dynamic> json) {
    return JWTToken(idToken: json['id_token']);
  }

  static JWTToken? fromJsonString(String json) => fromJson(jsonDecode(json));

  Map<String, dynamic>? toJson() {
    final Map<String, dynamic> json = {};
    if (idToken != null) json['id_token'] = idToken;
    return json;
  }

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
