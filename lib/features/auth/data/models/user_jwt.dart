import 'dart:convert';

import 'package:equatable/equatable.dart';

class UserJWT extends Equatable {
  final String? username;
  final String? password;

  const UserJWT(this.username, this.password);

  UserJWT copyWith({String? username, String? password}) {
    return UserJWT(username ?? this.username, password ?? this.password);
  }

  static UserJWT? fromJson(Map<String, dynamic> json) {
    return UserJWT(json['username'], json['password']);
  }

  static UserJWT? fromJsonString(String json) => fromJson(jsonDecode(json));

  Map<String, dynamic>? toJson() {
    final Map<String, dynamic> json = {};
    if (username != null) json['username'] = username;
    if (password != null) json['password'] = password;
    return json;
  }

  @override
  List<Object?> get props => [username, password];

  @override
  bool get stringify => true;
}
