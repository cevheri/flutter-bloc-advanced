import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

/// ApplicationUser model that represents the user entity in this application.
///
/// this is an immutable class that extends [Equatable] so that it can be compared
class User extends UserEntity {
  const User({
    super.id,
    super.login,
    super.firstName,
    super.lastName,
    super.email,
    super.activated,
    super.langKey,
    super.createdBy,
    super.createdDate,
    super.lastModifiedBy,
    super.lastModifiedDate,
    super.authorities,
  });

  /// Create a [User] (with serialization) from a plain [UserEntity].
  factory User.fromEntity(UserEntity entity) => User(
    id: entity.id,
    login: entity.login,
    firstName: entity.firstName,
    lastName: entity.lastName,
    email: entity.email,
    activated: entity.activated,
    langKey: entity.langKey,
    createdBy: entity.createdBy,
    createdDate: entity.createdDate,
    lastModifiedBy: entity.lastModifiedBy,
    lastModifiedDate: entity.lastModifiedDate,
    authorities: entity.authorities,
  );

  /// CopyWith method to create a new instance of the User class with new values
  @override
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
    );
  }

  static User? fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      login: json['login'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      activated: json['activated'],
      langKey: json['langKey'],
      createdBy: json['createdBy'],
      createdDate: json['createdDate'] != null ? DateTime.tryParse(json['createdDate']) : null,
      lastModifiedBy: json['lastModifiedBy'],
      lastModifiedDate: json['lastModifiedDate'] != null ? DateTime.tryParse(json['lastModifiedDate']) : null,
      authorities: json['authorities'] != null ? List<String>.from(json['authorities']) : null,
    );
  }

  static User? fromJsonString(String json) => fromJson(jsonDecode(json));

  static List<User> fromJsonList(List<dynamic> jsonList) => jsonList.map((json) => fromJson(json)!).toList();

  static List<User> fromJsonStringList(String jsonString) => fromJsonList(jsonDecode(jsonString));

  Map<String, dynamic>? toJson() {
    final Map<String, dynamic> json = {};
    if (id != null) json['id'] = id;
    if (login != null) json['login'] = login;
    if (firstName != null) json['firstName'] = firstName;
    if (lastName != null) json['lastName'] = lastName;
    if (email != null) json['email'] = email;
    if (activated != null) json['activated'] = activated;
    if (langKey != null) json['langKey'] = langKey;
    if (createdBy != null) json['createdBy'] = createdBy;
    if (createdDate != null) json['createdDate'] = createdDate!.toIso8601String();
    if (lastModifiedBy != null) json['lastModifiedBy'] = lastModifiedBy;
    if (lastModifiedDate != null) json['lastModifiedDate'] = lastModifiedDate!.toIso8601String();
    if (authorities != null) json['authorities'] = authorities;
    return json;
  }

  @override
  bool get stringify => true;
}
