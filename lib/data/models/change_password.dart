//////////////////////////////////////////

//String currentPassword;

//String newPassword;

import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class PasswordChangeDTO {
  @JsonProperty(name: 'currentPassword')
  final String? currentPassword;

  @JsonProperty(name: 'newPassword')
  final String? newPassword;

  const PasswordChangeDTO({
    this.currentPassword = '',
    this.newPassword = '',
  });

  @override
  String toString() {
    return 'PasswordChangeDTO{currentPassword: $currentPassword, newPassword: $newPassword}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordChangeDTO && runtimeType == other.runtimeType && currentPassword == other.currentPassword && newPassword == other.newPassword;

  @override
  int get hashCode => currentPassword.hashCode ^ newPassword.hashCode;
}
