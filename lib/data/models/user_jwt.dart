import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

@jsonSerializable
class UserJWT extends Equatable {
  @JsonProperty(name: 'username')
  final String? username;

  @JsonProperty(name: 'password')
  final String? password;

  const UserJWT(this.username, this.password);

  UserJWT copyWith({
    String? username,
    String? password,
  }) {
    return UserJWT(
      username ?? this.username,
      password ?? this.password,
    );
  }

  static UserJWT? fromJson(Map<String, dynamic> json) {
    return JsonMapper.fromMap<UserJWT>(json);
  }

  static UserJWT? fromJsonString(String json) {
    return JsonMapper.deserialize<UserJWT>(jsonDecode(json));
  }

  Map<String, dynamic>? toJson() => JsonMapper.toMap(this);

  @override
  String toString() {
    return 'UserJWT{password: $password}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserJWT && runtimeType == other.runtimeType && username == other.username && password == other.password;

  @override
  int get hashCode => username.hashCode ^ password.hashCode;

  @override
  List<Object?> get props => [username, password];

  @override
  bool get stringify => true;
}
