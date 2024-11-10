import 'package:flutter_bloc_advance/data/models/change_password.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test the Change Password model
void main() {
  late PasswordChangeDTO changePasswordModel;
  PasswordChangeDTO initChangePassword() {
    return PasswordChangeDTO(
      currentPassword: 'password',
      newPassword: 'new_password',
    );
  }

  setUp(() {
    initializeJsonMapper();
    changePasswordModel = initChangePassword();
  });

  group("Change Password Model", () {
    test('should create a ChangePassword instance (Constructor)', () {
      final finalChangePassword = changePasswordModel;

      expect(finalChangePassword.currentPassword, 'password');
      expect(finalChangePassword.newPassword, 'new_password');
    });

    test('should copy a ChangePassword instance with new values (copyWith)', () {
      final finalChangePassword = changePasswordModel;

      final updatedChangePassword = finalChangePassword.copyWith(
        currentPassword: 'new_password',
        newPassword: 'password',
      );

      expect(updatedChangePassword.currentPassword, 'new_password');
      expect(updatedChangePassword.newPassword, 'password');
    });

    test('should compare two ChangePassword instances', () {
      final finalChangePassword = changePasswordModel;

      final updatedChangePassword = finalChangePassword.copyWith(
        currentPassword: 'new_password',
        newPassword: 'password',
      );

      expect(finalChangePassword == updatedChangePassword, false);
    });
  });
}
