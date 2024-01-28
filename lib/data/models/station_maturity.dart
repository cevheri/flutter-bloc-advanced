import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/data/models/station.dart';

@jsonSerializable
class StationMaturity extends Equatable {
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

  @JsonProperty(name: 'cost')
  final double? cost;

  @JsonProperty(name: 'station')
  final Station? station;

  StationMaturity({
    this.createdBy,
    this.createdDate,
    this.lastModifiedBy,
    this.lastModifiedDate,
    this.id,
    this.maturity,
    this.rate,
    this.cost,
    this.station,
  });

  StationMaturity copyWith({
    String? createdBy,
    String? createdDate,
    String? lastModifiedBy,
    String? lastModifiedDate,
    int? id,
    int? maturity,
    double? rate,
    double? cost,
    Station? station,
  }) {
    return StationMaturity(
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      id: id ?? this.id,
      maturity: maturity ?? this.maturity,
      rate: rate ?? this.rate,
      cost: cost ?? this.cost,
      station: station ?? this.station,
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
      cost,
      station,
    ];
  }

  @override
  bool get stringify => true;

}
