import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class UserJWT {

  @JsonProperty(name: 'username')
  String? username;

  @JsonProperty(name: 'password')
  String? password;

  UserJWT(this.username, this.password);

  @override
  String toString() {
    return 'UserJWT{password: $password}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserJWT &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          password == other.password;

  @override
  int get hashCode => username.hashCode ^ password.hashCode;
}
