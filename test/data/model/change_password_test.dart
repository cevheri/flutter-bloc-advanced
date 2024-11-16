import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

/// Test the Change Password model
void main() {
  var model = mockPasswordChangePayload;

  setUp(() {
    initializeJsonMapper();
  });

  group("Change Password Model", () {
    test('should create a ChangePassword instance (Constructor)', () {
      expect(model.currentPassword, 'password');
      expect(model.newPassword, 'new_password');
    });

    test('should copy a ChangePassword instance with new values (copyWith)', () {
      final updatedChangePassword = model.copyWith(
        currentPassword: 'new_password',
        newPassword: 'password',
      );

      expect(updatedChangePassword.currentPassword, 'new_password');
      expect(updatedChangePassword.newPassword, 'password');
    });

    test('should compare two ChangePassword instances', () {
      final updatedChangePassword = model.copyWith(
        currentPassword: 'new_password',
        newPassword: 'password',
      );

      expect(model == updatedChangePassword, false);
    });
  });
}
