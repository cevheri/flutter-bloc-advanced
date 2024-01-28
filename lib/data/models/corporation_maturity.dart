import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/data/models/corporation.dart';

@jsonSerializable
class CorporationMaturity extends Equatable {
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

  @JsonProperty(name: 'maturity')
  final int? maturity;

  @JsonProperty(name: 'rate')
  final double? rate;


  @JsonProperty(name: 'corporation')
  final Corporation? corporation;

  CorporationMaturity({
    this.createdBy,
    this.createdDate,
    this.lastModifiedBy,
    this.lastModifiedDate,
    this.id,
    this.maturity,
    this.rate,
    this.corporation,
  });

  CorporationMaturity copyWith({
    String? createdBy,
    String? createdDate,
    String? lastModifiedBy,
    String? lastModifiedDate,
    int? id,
    int? maturity,
    double? rate,
    Corporation? corporation,
  }) {
    return CorporationMaturity(
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      id: id ?? this.id,
      maturity: maturity ?? this.maturity,
      rate: rate ?? this.rate,
      corporation: corporation ?? this.corporation,
    );
  }

  @override
  List<Object?> get props {
    return [
      createdBy,
      createdDate,
      lastModifiedBy,
      lastModifiedDate,
      id,
      maturity,
      rate,
      corporation,
    ];
  }

  @override
  bool get stringify => true;

}
