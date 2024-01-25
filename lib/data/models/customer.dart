import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/data/models/sales_person.dart';

/// ApplicationCustomer model that represents the customer entity in this application.
///
/// this is an immutable class that extends [Equatable] so that it can be compared

/*
[
  {
    "id": "120-03-004",
    "name": "KA BETON PARKE BORU VE PREFABRİK İNŞ.SAN.VE TAAH.A.Ş.",
    "customerShortName": "KA BETON PARKE BORU VE PREFABRİK İNŞ.SAN.VE TAAH.A.Ş.",
    "cariKodu": "120-03-004",
    "official": "",
    "phone": "0272 213 27 31",
    "email": null,
    "vatNo": "4841547722",
    "taxOffice": "TINAZTEPE",
    "cityName": "AFYON",
    "districtName": "MERKEZ",
    "address": "BURMALI MAH.MİLLİ EGEMENLİK CAD.ÖZEL İDARE NO:20",
    "active": true,
    "salesPersonCode": "06",
    "debt": 0,
    "credit": 0,
    "salesPerson": {
      "id": "06",
      "name": "S.YILMAZ KALENDER",
      "code": "06",
      "active": true
    }
  },
]
 */
@jsonSerializable
class Customer extends Equatable {
  @JsonProperty(name: 'id')
  final String? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'customerShortName')
  final String? customerShortName;

  @JsonProperty(name: 'cariKodu')
  final String? cariKodu;

  @JsonProperty(name: 'official')
  final String? official;

  @JsonProperty(name: 'phone')
  final String? phone;

  @JsonProperty(name: 'email')
  final String? email;

  @JsonProperty(name: 'vatNo')
  final String? vatNo;

  @JsonProperty(name: 'taxOffice')
  final String? taxOffice;

  @JsonProperty(name: 'cityName')
  final String? cityName;

  @JsonProperty(name: 'districtName')
  final String? districtName;

  @JsonProperty(name: 'address')
  final String? address;

  @JsonProperty(name: 'active')
  final bool? active;

  @JsonProperty(name: 'salesPersonCode')
  final String? salesPersonCode;

  @JsonProperty(name: 'debt')
  final double? debt;

  @JsonProperty(name: 'credit')
  final double? credit;

  @JsonProperty(name: 'salesPerson')
  final SalesPerson? salesPerson;


  const Customer({
    this.id,
    this.name,
    this.customerShortName,
    this.cariKodu,
    this.official,
    this.phone,
    this.email,
    this.vatNo,
    this.taxOffice,
    this.cityName,
    this.districtName,
    this.address,
    this.active,
    this.salesPersonCode,
    this.debt,
    this.credit,
    this.salesPerson,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? customerShortName,
    String? cariKodu,
    String? official,
    String? phone,
    String? email,
    String? vatNo,
    String? taxOffice,
    String? cityName,
    String? districtName,
    String? address,
    bool? active,
    String? salesPersonCode,
    double? debt,
    double? credit,
    SalesPerson? salesPerson,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      customerShortName: customerShortName ?? this.customerShortName,
      cariKodu: cariKodu ?? this.cariKodu,
      official: official ?? this.official,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vatNo: vatNo ?? this.vatNo,
      taxOffice: taxOffice ?? this.taxOffice,
      cityName: cityName ?? this.cityName,
      districtName: districtName ?? this.districtName,
      address: address ?? this.address,
      active: active ?? this.active,
      salesPersonCode: salesPersonCode ?? this.salesPersonCode,
      debt: debt ?? this.debt,
      credit: credit ?? this.credit,
      salesPerson: salesPerson ?? this.salesPerson,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        customerShortName,
        cariKodu,
        official,
        phone,
        email,
        vatNo,
        taxOffice,
        cityName,
        districtName,
        address,
        active,
        salesPersonCode,
        debt,
        credit,
        salesPerson,
      ];

  @override
  bool get stringify => true;
}
