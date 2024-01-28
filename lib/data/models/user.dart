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

  @JsonProperty(name: 'cariKodu')
  final String? cariKodu;

  @JsonProperty(name: 'phoneNumber')
  final String? phoneNumber;

  @JsonProperty(name: 'salesPersonCode')
  final String? salesPersonCode;

  @JsonProperty(name: 'salesPersonName')
  final String? salesPersonName;

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
    this.cariKodu,
    this.phoneNumber,
    this.salesPersonCode,
    this.salesPersonName,
  });

  User copyWith({
    int? id,
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
    String? cariKodu,
    String? phoneNumber,
    String? salesPersonCode,
    String? salesPersonName,
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
      cariKodu: cariKodu ?? this.cariKodu,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      salesPersonCode: salesPersonCode ?? this.salesPersonCode,
      salesPersonName: salesPersonName ?? this.salesPersonName,
    );
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
        cariKodu,
        phoneNumber,
        salesPersonCode,
        salesPersonName,
      ];

  @override
  bool get stringify => true;
}
