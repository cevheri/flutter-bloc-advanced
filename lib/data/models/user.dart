import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

/// ApplicationUser model that represents the user entity in this application.
///
/// this is an immutable class that extends [Equatable] so that it can be compared
@jsonSerializable
class User extends Equatable {
  @JsonProperty(name: 'id')
  final String? id;

  @JsonProperty(name: 'login')
  final String? login;

  @JsonProperty(name: 'firstName')
  final String? firstName;

  @JsonProperty(name: 'lastName')
  final String? lastName;

  @JsonProperty(name: 'email')
  final String? email;

  @JsonProperty(name: 'activated')
  final bool? activated;

  @JsonProperty(name: 'langKey')
  final String? langKey;

  @JsonProperty(name: 'createdBy')
  final String? createdBy;

  @JsonProperty(name: 'createdDate')
  final DateTime? createdDate;

  @JsonProperty(name: 'lastModifiedBy')
  final String? lastModifiedBy;

  @JsonProperty(name: 'lastModifiedDate')
  final DateTime? lastModifiedDate;

  @JsonProperty(name: 'authorities')
  final List<String>? authorities;

  // @JsonProperty(name: 'phoneNumber')
  // final String? phoneNumber;

  const User({
    this.id,
    this.login,
    this.firstName,
    this.lastName,
    this.email,
    this.activated,
    this.langKey,
    this.createdBy,
    this.createdDate,
    this.lastModifiedBy,
    this.lastModifiedDate,
    this.authorities,
    // this.phoneNumber,
  });

  User copyWith({
    String? id,
    String? login,
    String? firstName,
    String? lastName,
    String? email,
    bool? activated,
    String? langKey,
    String? createdBy,
    DateTime? createdDate,
    String? lastModifiedBy,
    DateTime? lastModifiedDate,
    List<String>? authorities,
    // String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      login: login ?? this.login,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      activated: activated ?? this.activated,
      langKey: langKey ?? this.langKey,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      authorities: authorities ?? this.authorities,
      // phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  static User? fromJson(Map<String, dynamic> json) {
    var result = JsonMapper.deserialize<User>(json);
    if (result == null) {
      return null;
    }
    return result;
  }

  static User? fromJsonString(String json) {
    var result = JsonMapper.deserialize<User>(jsonDecode(json));
    if (result == null) {
      return null;
    }
    return result;
  }

  @override
  List<Object?> get props => [
        id,
        login,
        firstName,
        lastName,
        email,
        activated,
        langKey,
        createdBy,
        createdDate,
        lastModifiedBy,
        lastModifiedDate,
        authorities,
        // phoneNumber,
      ];

  @override
  bool get stringify => true;
}
