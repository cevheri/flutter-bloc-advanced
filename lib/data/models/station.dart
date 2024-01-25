import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

import 'city.dart';
import 'corporation.dart';
import 'district.dart';

@jsonSerializable
class Station extends Equatable{
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

  @JsonProperty(name: 'active')
  final bool? active;

  @JsonProperty(name: 'corporation')
  final Corporation? corporation;

  @JsonProperty(name: 'city')
  final City? city;

  @JsonProperty(name: 'district')
  final District? district;

  Station(
      {this.createdBy,
      this.createdDate,
      this.lastModifiedBy,
      this.lastModifiedDate,
      this.id,
      this.name,
      this.active,
      this.corporation,
      this.city,
      this.district});

  Station copyWith({
    String? createdBy,
    String? createdDate,
    String? lastModifiedBy,
    String? lastModifiedDate,
    int? id,
    String? name,
    bool? active,
    Corporation? corporation,
    City? city,
    District? district,
  }) {
    return Station(
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      corporation: corporation ?? this.corporation,
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
        active,
        corporation,
        city,
        district
      ];

  @override
  bool get stringify => true;
}
