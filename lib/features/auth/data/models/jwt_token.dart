import 'dart:convert';

import 'package:equatable/equatable.dart';

class JWTToken extends Equatable {
  final String? idToken;
  final String? refreshToken;

  const JWTToken({this.idToken, this.refreshToken});

  JWTToken copyWith({String? idToken, String? refreshToken}) {
    return JWTToken(idToken: idToken ?? this.idToken, refreshToken: refreshToken ?? this.refreshToken);
  }

  static JWTToken? fromJson(Map<String, dynamic> json) {
    return JWTToken(idToken: json['id_token'], refreshToken: json['refresh_token']);
  }

  static JWTToken? fromJsonString(String json) => fromJson(jsonDecode(json));

  Map<String, dynamic>? toJson() {
    final Map<String, dynamic> json = {};
    if (idToken != null) json['id_token'] = idToken;
    if (refreshToken != null) json['refresh_token'] = refreshToken;
    return json;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JWTToken &&
          runtimeType == other.runtimeType &&
          idToken == other.idToken &&
          refreshToken == other.refreshToken;

  @override
  int get hashCode => Object.hash(idToken, refreshToken);

  @override
  List<Object?> get props => [idToken, refreshToken];

  @override
  bool get stringify => true;
}
