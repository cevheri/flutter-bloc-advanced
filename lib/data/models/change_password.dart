import 'dart:convert';

import 'package:equatable/equatable.dart';

class PasswordChangeDTO extends Equatable {
  final String? currentPassword;
  final String? newPassword;

  const PasswordChangeDTO({this.currentPassword, this.newPassword});

  PasswordChangeDTO copyWith({String? currentPassword, String? newPassword}) {
    return PasswordChangeDTO(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
    );
  }

  static PasswordChangeDTO? fromJson(Map<String, dynamic> json) {
    return PasswordChangeDTO(
      currentPassword: json['currentPassword'],
      newPassword: json['newPassword'],
    );
  }

  static PasswordChangeDTO? fromJsonString(String json) => fromJson(jsonDecode(json));

  Map<String, dynamic>? toJson() {
    final Map<String, dynamic> json = {};
    if (currentPassword != null) json['currentPassword'] = currentPassword;
    if (newPassword != null) json['newPassword'] = newPassword;
    return json;
  }

  @override
  List<Object?> get props => [currentPassword, newPassword];

  @override
  bool get stringify => true;
}
