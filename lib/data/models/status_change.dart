import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';


@jsonSerializable
class StatusChange extends Equatable {
  @JsonProperty(name: 'offeringId')
  final int? offeringId;

  @JsonProperty(name: 'statusId')
  final int? statusId;
  @JsonProperty(name: 'comment')
  final String? comment;

  const StatusChange({
    this.offeringId,
    this.statusId,
    this.comment,
  });

  StatusChange copyWith({
    int? offeringId,
    int? statusId,
    String? comment,
  }) {
    return StatusChange(
      offeringId: offeringId ?? this.offeringId,
      statusId: statusId ?? this.statusId,
      comment: comment ?? this.comment,
    );
  }

  @override
  List<Object?> get props => [
        offeringId,
        statusId,
        comment,
      ];

  @override
  bool get stringify => true;
}
