import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class JWTToken {

  @JsonProperty(name: 'id_token')
  String? idToken;


  @override
  String toString() {
    return 'JWTToken{idToken: $idToken}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JWTToken &&
          runtimeType == other.runtimeType &&
          idToken == other.idToken;

  @override
  int get hashCode => idToken.hashCode;
}
