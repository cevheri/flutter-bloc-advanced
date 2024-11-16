import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

/// ApplicationCustomer model that represents the customer entity in this application.
///
/// this is an immutable class that extends [Equatable] so that it can be compared

@jsonSerializable
class Customer extends Equatable {
  @JsonProperty(name: 'id')
  final String? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'phone')
  final String? phone;

  @JsonProperty(name: 'email')
  final String? email;

  @JsonProperty(name: 'cityName')
  final String? cityName;

  @JsonProperty(name: 'districtName')
  final String? districtName;

  @JsonProperty(name: 'address')
  final String? address;

  @JsonProperty(name: 'active')
  final bool? active;

  const Customer({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.cityName,
    this.districtName,
    this.address,
    this.active,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? cityName,
    String? districtName,
    String? address,
    bool? active,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      cityName: cityName ?? this.cityName,
      districtName: districtName ?? this.districtName,
      address: address ?? this.address,
      active: active ?? this.active,
    );
  }

  static Customer? fromJson(Map<String, dynamic> json) {
    var result = JsonMapper.fromMap<Customer>(json);
    if (result == null) {
      return null;
    }
    return result;
  }

  static Customer? fromJsonString(String json){
    var result = JsonMapper.deserialize<Customer>(jsonDecode(json));
    if (result == null) {
      return null;
    }
    return result;
  }

  Map<String, dynamic>? toJson() => JsonMapper.toMap(this);

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        cityName,
        districtName,
        address,
        active,
      ];

  @override
  bool get stringify => true;
}
