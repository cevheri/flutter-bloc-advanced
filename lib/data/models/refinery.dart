import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/data/models/district.dart';

import 'city.dart';

@jsonSerializable
class Refinery extends Equatable {
  @JsonProperty(name: 'createdBy')
  final String? createdBy;

  @JsonProperty(name: 'createdDate')
  final String? createdDate;

  @JsonProperty(name: 'lastModifiedBy')
  final String? lastModifiedBy;

  @JsonProperty(name: 'lastModifiedDate')
  final String? lastModifiedDate;

  @JsonProperty(name: 'id')
  final int? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'description')
  final String? description;

  @JsonProperty(name: 'active')
  final bool? active;

  @JsonProperty(name: 'price')
  final double? price;

  @JsonProperty(name: 'priceWithVat')
  final double? priceWithVat;

  @JsonProperty(name: 'city')
  final City? city;

  @JsonProperty(name: 'district')
  final District? district;

  const Refinery({
    this.createdBy,
    this.createdDate,
    this.lastModifiedBy,
    this.lastModifiedDate,
    this.id,
    this.name,
    this.description,
    this.active,
    this.price,
    this.priceWithVat,
    this.city,
    this.district,
  });

  Refinery copyWith({
    String? createdBy,
    String? createdDate,
    String? lastModifiedBy,
    String? lastModifiedDate,
    int? id,
    String? name,
    String? description,
    bool? active,
    double? price,
    double? priceWithVat,
    City? city,
    District? district,
  }) {
    return Refinery(
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      price: price ?? this.price,
      priceWithVat: priceWithVat ?? this.priceWithVat,
      city: city ?? this.city,
      district: district ?? this.district,
    );
  }

  @override
  List<Object?> get props => [
        createdBy,
        createdDate,
        lastModifiedBy,
        lastModifiedDate,
        id,
        name,
        description,
        active,
        price,
        priceWithVat,
        city,
        district,
      ];

  @override
  bool get stringify => true;

}
