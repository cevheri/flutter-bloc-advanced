import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/change_password.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

/// Test the Change Password model
void main() {
  setUp(() {
    initializeJsonMapper();
  });

  group("Change Password Model", () {
    test('should create a ChangePassword instance (Constructor)', () {
      expect(mockPasswordChangePayload.currentPassword, 'password');
      expect(mockPasswordChangePayload.newPassword, 'new_password');
    });

    test('should copy a ChangePassword instance with new values (copyWith)', () {
      final entityUpd = mockPasswordChangePayload.copyWith(currentPassword: 'new_password', newPassword: 'password');

      expect(entityUpd.currentPassword, 'new_password');
      expect(entityUpd.newPassword, 'password');
    });

    test('should copy a ChangePassword instance with new values (copyWith)', () {
      final entityUpd = mockPasswordChangePayload.copyWith();

      expect(entityUpd == mockPasswordChangePayload, true);
    });

    test('should compare two ChangePassword instances', () {
      final entityUpd = mockPasswordChangePayload.copyWith(currentPassword: 'new_password', newPassword: 'password');

      expect(mockPasswordChangePayload == entityUpd, false);
    });
  });

  //fromJson, fromJsonString, toJson, props, toString
  group("Change Password Model Json Test", () {
    test('should convert ChangePassword from Json', () {
      final json = mockPasswordChangePayload.toJson();
      final entity = PasswordChangeDTO.fromJson(json!);

      expect(entity?.currentPassword, 'password');
      expect(entity?.newPassword, 'new_password');
    });

    test('should convert ChangePassword from JsonString', () {
      final jsonString = jsonEncode(mockPasswordChangePayload.toJson());
      final entity = PasswordChangeDTO.fromJsonString(jsonString);

      expect(entity?.currentPassword, 'password');
      expect(entity?.newPassword, 'new_password');
    });

    test('should convert ChangePassword to Json', () {
      final json = mockPasswordChangePayload.toJson()!;

      expect(json['currentPassword'], 'password');
      expect(json['newPassword'], 'new_password');
    });

    test('should compare two ChangePassword instances props', () {
      final entityUpd = mockPasswordChangePayload.copyWith(currentPassword: 'new_password', newPassword: 'password');

      expect(mockPasswordChangePayload.props == entityUpd.props, false);
    });

    test('should compare two ChangePassword instances toString', () {
      final entityUpd = mockPasswordChangePayload.copyWith(currentPassword: 'new_password', newPassword: 'password');

      expect(mockPasswordChangePayload.toString() == entityUpd.toString(), false);
    });
  });
}
