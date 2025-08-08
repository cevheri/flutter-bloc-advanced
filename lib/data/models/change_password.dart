import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

@jsonSerializable
class PasswordChangeDTO extends Equatable {
  @JsonProperty(name: 'currentPassword')
  final String? currentPassword;

  @JsonProperty(name: 'newPassword')
  final String? newPassword;

  const PasswordChangeDTO({this.currentPassword, this.newPassword});

  PasswordChangeDTO copyWith({String? currentPassword, String? newPassword}) {
    return PasswordChangeDTO(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
    );
  }

  static PasswordChangeDTO? fromJson(Map<String, dynamic> json) {
    var result = JsonMapper.fromMap<PasswordChangeDTO>(json);
    if (result == null) {
      return null;
    }
    return result;
  }

  static PasswordChangeDTO? fromJsonString(String json) {
    var result = JsonMapper.deserialize<PasswordChangeDTO>(jsonDecode(json));
    if (result == null) {
      return null;
    }
    return result;
  }

  Map<String, dynamic>? toJson() => JsonMapper.toMap(this);

  @override
  List<Object?> get props => [currentPassword, newPassword];

  @override
  bool get stringify => true;
}
