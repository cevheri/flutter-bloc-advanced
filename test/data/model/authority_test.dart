import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

/// Test the Authorities model
void main() {
  var model = mockAuthorityPayload;

  setUp(() {
    initializeJsonMapper();
  });

  group("Authorities Model", () {
    test('should create a Authorities instance (Constructor)', () {
      expect(model.name, 'ROLE_USER');
    });

    test('should copy a Authorities instance with new values (copyWith)', () {
      final updatedAuthorities = model.copyWith(
        name: 'ROLE_ADMIN',
      );

      expect(updatedAuthorities.name, 'ROLE_ADMIN');
    });

    test('should compare two Authorities instances', () {
      final finalAuthorities = model;

      final updatedAuthorities = finalAuthorities.copyWith(
        name: 'ROLE_ADMIN',
      );

      expect(finalAuthorities == updatedAuthorities, false);
    });
  });
}
