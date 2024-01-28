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

}
