import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/data/models/refinery.dart';
import 'package:flutter_bloc_advance/data/models/station.dart';
import 'package:flutter_bloc_advance/data/models/station_maturity.dart';
import 'package:flutter_bloc_advance/data/models/status.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';

import 'city.dart';
import 'corporation.dart';
import 'corporation_maturity.dart';
import 'customer.dart';
import 'district.dart';



@jsonSerializable
class Offer extends Equatable {
  @JsonProperty(name: 'createdBy')
  final String? createdBy;
  @JsonProperty(name: 'createdDate')
  final String? createdDate;
  @JsonProperty(name: 'lastModifiedBy')
  final String? lastModifiedBy;
  @JsonProperty(name: 'lastModifiedDate')
  final String? lastModifiedDate;
  @JsonProperty(name: 'shipmentDate')
  final String? shipmentDate;
  @JsonProperty(name: 'id')
  final int? id;
  @JsonProperty(name: 'offeringType')
  final String? offeringType;
  @JsonProperty(name: 'description')
  final String? description;
  @JsonProperty(name: 'increase')
  final double? increase;
  @JsonProperty(name: 'decrease')
  final double? decrease;
  @JsonProperty(name: 'rate')
  final double? rate;
  @JsonProperty(name: 'active')
  final bool? active;
  @JsonProperty(name: 'completed')
  final bool? completed;
  @JsonProperty(name: 'transportDistance')
  final double? transportDistance;
  @JsonProperty(name: 'transportCost')
  final double? transportCost;
  @JsonProperty(name: 'maturity')
  final int? maturity;
  @JsonProperty(name: 'liter')
  final double? liter;
  @JsonProperty(name: 'debt')
  final double? debt;
  @JsonProperty(name: 'credit')
  final double? credit;
  @JsonProperty(name: 'unitPrice')
  final double? unitPrice;
  @JsonProperty(name: 'totalPrice')
  final double? totalPrice;
  @JsonProperty(name: 'status')
  final Status? status;
  @JsonProperty(name: 'corporation')
  final Corporation? corporation;
  @JsonProperty(name: 'station')
  final Station? station;
  @JsonProperty(name: 'destinationCity')
  final City? destinationCity;
  @JsonProperty(name: 'destinationDistrict')
  final District? destinationDistrict;
  @JsonProperty(name: 'customer')
  final Customer? customer;
  @JsonProperty(name: 'user')
  final User? user;
  @JsonProperty(name: 'refinery')
  final Refinery? refinery;

  @JsonProperty(name: 'selectedCorporationMaturityDate')
  final CorporationMaturity? selectedCorporationMaturityDate;

  @JsonProperty(name: 'selectedStationMaturityPrice')
  final StationMaturity? selectedStationMaturityPrice;

  const Offer({
    this.createdBy,
    this.createdDate,
    this.lastModifiedBy,
    this.lastModifiedDate,
    this.shipmentDate,
    this.id,
    this.offeringType,
    this.description,
    this.increase,
    this.decrease,
    this.rate,
    this.active,
    this.completed,
    this.transportDistance,
    this.transportCost,
    this.maturity,
    this.liter,
    this.debt,
    this.credit,
    this.unitPrice,
    this.totalPrice,
    this.status,
    this.corporation,
    this.station,
    this.destinationCity,
    this.destinationDistrict,
    this.customer,
    this.user,
    this.refinery,
    this.selectedCorporationMaturityDate,
    this.selectedStationMaturityPrice,
  });

  Offer copyWith({
    String? createdBy,
    String? createdDate,
    String? lastModifiedBy,
    String? lastModifiedDate,
    String? shipmentDate,
    int? id,
    String? offeringType,
    String? description,
    double? increase,
    double? decrease,
    double? rate,
    bool? active,
    bool? completed,
    double? transportDistance,
    double? transportCost,
    int? maturity,
    double? liter,
    double? debt,
    double? credit,
    double? unitPrice,
    double? totalPrice,
    Status? status,
    Corporation? corporation,
    Station? station,
    City? destinationCity,
    District? destinationDistrict,
    Customer? customer,
    User? user,
    Refinery? refinery,
    CorporationMaturity? selectedCorporationMaturityDate,
    StationMaturity? selectedStationMaturityPrice,
  }) {
    return Offer(
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      shipmentDate: shipmentDate ?? this.shipmentDate,
      id: id ?? this.id,
      offeringType: offeringType ?? this.offeringType,
      description: description ?? this.description,
      increase: increase ?? this.increase,
      decrease: decrease ?? this.decrease,
      rate: rate ?? this.rate,
      active: active ?? this.active,
      completed: completed ?? this.completed,
      transportDistance: transportDistance ?? this.transportDistance,
      transportCost: transportCost ?? this.transportCost,
      maturity: maturity ?? this.maturity,
      liter: liter ?? this.liter,
      debt: debt ?? this.debt,
      credit: credit ?? this.credit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      corporation: corporation ?? this.corporation,
      station: station ?? this.station,
      destinationCity: destinationCity ?? this.destinationCity,
      destinationDistrict: destinationDistrict ?? this.destinationDistrict,
      customer: customer ?? this.customer,
      user: user ?? this.user,
      refinery: refinery ?? this.refinery,
      selectedCorporationMaturityDate: selectedCorporationMaturityDate ?? this.selectedCorporationMaturityDate,
      selectedStationMaturityPrice: selectedStationMaturityPrice ?? this.selectedStationMaturityPrice,
    );
  }

  @override
  List<Object?> get props => [
    createdBy,
    createdDate,
    lastModifiedBy,
    lastModifiedDate,
    shipmentDate,
    id,
    offeringType,
    description,
    increase,
    decrease,
    rate,
    active,
    completed,
    transportDistance,
    transportCost,
    maturity,
    liter,
    debt,
    credit,
    unitPrice,
    totalPrice,
    status,
    corporation,
    station,
    destinationCity,
    destinationDistrict,
    customer,
    user,
    refinery,
    selectedCorporationMaturityDate,
    selectedStationMaturityPrice,
  ];

  @override
  bool get stringify => true;

}
