import 'package:dart_json_mapper/dart_json_mapper.dart';

/// ApplicationUser model that represents the user entity in this application.
@jsonSerializable
class User {
  @JsonProperty(name: 'id')
  final String? id;

  @JsonProperty(name: 'login')
  final String? login;

  @JsonProperty(name: 'first_name')
  final String? firstName;

  @JsonProperty(name: 'last_name')
  final String? lastName;

  @JsonProperty(name: 'email')
  final String? email;

  @JsonProperty(name: 'lang_key')
  final String? langKey;

  User({
    this.id = '',
    this.login = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.langKey = 'en',
  });

  /// Creates a copy of this ApplicationUser but with the given fields
  User copyWith({
    String? id,
    String? login,
    String? firstName,
    String? lastName,
    String? email,
    String? langKey,
  }) {
    return User(
      id: id ?? this.id,
      login: login ?? this.login,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      langKey: langKey ?? this.langKey,
    );
  }

}
