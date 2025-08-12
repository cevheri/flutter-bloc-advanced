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

  static Customer? fromJson(Map<String, dynamic> jsonDict) {
    return Customer(
      id: jsonDict["id"],
      name: jsonDict["name"],
      phone: jsonDict["phone"],
      email: jsonDict["email"],
      cityName: jsonDict["cityName"],
      districtName: jsonDict["districtName"],
      address: jsonDict["address"],
      active: jsonDict["active"],
    );
  }

  static Customer? fromJsonString(String json) {
    if (json == "") return null;
    final customerDict = jsonDecode(json);
    return fromJson(customerDict);
  }

  Map<String, dynamic>? toJson() {
    final Map<String, dynamic> json = {};
    if (id != null) {
      json["id"] = id;
    }
    if (name != null) {
      json["name"] = name;
    }
    if (phone != null) {
      json["phone"] = phone;
    }
    if (email != null) {
      json["email"] = email;
    }
    if (cityName != null) {
      json["cityName"] = cityName;
    }
    if (districtName != null) {
      json["districtName"] = districtName;
    }
    if (address != null) {
      json["address"] = address;
    }
    if (active != null) {
      json["active"] = active;
    }
    return json;
  }

  @override
  List<Object?> get props => [id, name, phone, email, cityName, districtName, address, active];

  @override
  bool get stringify => true;
}
