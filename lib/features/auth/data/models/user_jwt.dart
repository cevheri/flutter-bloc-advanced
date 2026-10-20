import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';

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

  /// The password is masked, so the model is safe to print in a log line or the dev console.
  @override
  String toString() => 'UserJWT(username: $username, password: $secretMask)';
}
