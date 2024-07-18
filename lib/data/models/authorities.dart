import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

@jsonSerializable
class Authorities extends Equatable {
  @JsonProperty(name: 'name')
  final String? name;

  const Authorities({
    this.name,
  });

  Authorities copyWith({
    String? name,
  }) {
    return Authorities(
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [
        name,
      ];

  @override
  bool get stringify => true;
}
