import 'package:flutter_bloc_advance/features/users/domain/user_roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('primaryRole', () {
    test('is the admin role when the user has it, wherever the server lists it', () {
      expect(primaryRole(['ROLE_ADMIN', 'ROLE_USER']), adminRole);
      expect(primaryRole(['ROLE_USER', 'ROLE_ADMIN']), adminRole);
    });

    test('is the first role of a user who is not an admin', () {
      expect(primaryRole(['ROLE_USER']), 'ROLE_USER');
      expect(primaryRole(['ROLE_MANAGER', 'ROLE_USER']), 'ROLE_MANAGER');
    });

    test('is null for a user without a role', () {
      expect(primaryRole(null), isNull);
      expect(primaryRole(const []), isNull);
    });
  });
}
