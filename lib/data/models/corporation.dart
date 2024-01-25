import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';



@jsonSerializable
class Corporation  extends Equatable  {
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


  const Corporation({
    this.createdBy,
    this.createdDate,
    this.lastModifiedBy,
    this.lastModifiedDate,
    this.id,
    this.name,
    this.description,
    this.active,
  });

  Corporation copyWith({
    String? createdBy,
    String? createdDate,
    String? lastModifiedBy,
    String? lastModifiedDate,
    int? id,
    String? name,
    String? description,
    bool? active,
  }) {
    return Corporation(
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
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
  ];

  @override
  bool get stringify => true;
}
