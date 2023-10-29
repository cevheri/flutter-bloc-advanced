import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

/// ApplicationUser model that represents the user entity in this application.
///
/// this is an immutable class that extends [Equatable] so that it can be compared
@jsonSerializable
class User extends Equatable {
  @JsonProperty(name: 'id')
  final int? id;

  @JsonProperty(name: 'login')
  final String? login;

  @JsonProperty(name: 'firstName')
  final String? firstName;

  @JsonProperty(name: 'lastName')
  final String? lastName;

  @JsonProperty(name: 'email')
  final String? email;

  @JsonProperty(name: 'langKey')
  final String? langKey;

  final bool? activated;

  final String? imageUrl;

  const User({
    this.id = 0,
    this.login = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.langKey = 'en',
    this.activated = false,
    this.imageUrl = '',
  });

  User copyWith({
    int? id,
    String? login,
    String? firstName,
    String? lastName,
    String? email,
    String? langKey,
    bool? activated,
    String? imageUrl,
  }) {
    return User(
      id: id ?? this.id,
      login: login ?? this.login,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      langKey: langKey ?? this.langKey,
      activated: activated ?? this.activated,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        login,
        firstName,
        lastName,
        email,
        langKey,
        activated,
        imageUrl,
      ];

  @override
  bool get stringify => true;
}
