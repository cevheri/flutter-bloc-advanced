import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc_advance/data/models/status.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';

import 'authorities.dart';

/*
{
  "id": 3,
  "name": "APPROVAL_IN_PROGRESS",
  "description": "Teklif onaylama işlemi için yönlendirildi.",
  "orderPriority": 3,
  "active": true,
  "nexts": [
    {
      "id": 2,
      "name": "CANCELLED",
      "description": "Bir taslak teklif oluşturuldu ve ardından onaylama veya müşteriye sunma öncesinde iptal edildi.",
      "orderPriority": 2,
      "active": true
    },
    {
      "id": 4,
      "name": "APPROVAL_REJECTED",
      "description": "Teklif onaylama isteği reddedildi.",
      "orderPriority": 4,
      "active": true
    },
    {
      "id": 5,
      "name": "APPROVED",
      "description": "Teklif onaylandı ve teklif müşteriye gönderilmeye hazır.",
      "orderPriority": 5,
      "active": true
    }
  ],
  "authorities": [
    {
      "name": "ROLE_MARKETING"
    },
    {
      "name": "ROLE_ADMIN"
    }
  ],
  "parents": null
}
 */

@jsonSerializable
class StatusNext extends Equatable {
  @JsonProperty(name: 'id')
  final int? id;

  @JsonProperty(name: 'name')
  final String? name;

  @JsonProperty(name: 'description')
  final String? description;

  @JsonProperty(name: 'orderPriority')
  final int? orderPriority;

  @JsonProperty(name: 'active')
  final bool? active;

  @JsonProperty(name: 'nexts')
  final List<Status?>? nexts;

  @JsonProperty(name: 'authorities')
  final List<Authorities?>? authorities;

  const StatusNext({
    this.id,
    this.name,
    this.description,
    this.orderPriority,
    this.active,
    this.nexts,
    this.authorities,
  });

  StatusNext copyWith({
    int? id,
    String? name,
    String? description,
    int? orderPriority,
    bool? active,
    List<Status?>? nexts,
    List<Authorities?>? authorities,
  }) {
    return StatusNext(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      orderPriority: orderPriority ?? this.orderPriority,
      active: active ?? this.active,
      nexts: nexts ?? this.nexts,
      authorities: authorities ?? this.authorities,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        orderPriority,
        active,
        nexts,
        authorities,
      ];

  @override
  bool get stringify => true;
}
