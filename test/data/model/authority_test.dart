import 'package:flutter_bloc_advance/data/models/authorities.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test the Authorities model
void main() {
  late Authorities authoritiesModel;
  Authorities initAuthorities() {
    return Authorities(
      name: 'ROLE_USER',
    );
  }

  setUp(() {
    initializeJsonMapper();
    authoritiesModel = initAuthorities();
  });

  group("Authorities Model", () {
    test('should create a Authorities instance (Constructor)', () {
      final finalAuthorities = authoritiesModel;

      expect(finalAuthorities.name, 'ROLE_USER');
    });

    test('should copy a Authorities instance with new values (copyWith)', () {
      final finalAuthorities = authoritiesModel;

      final updatedAuthorities = finalAuthorities.copyWith(
        name: 'ROLE_ADMIN',
      );

      expect(updatedAuthorities.name, 'ROLE_ADMIN');
    });

    test('should compare two Authorities instances', () {
      final finalAuthorities = authoritiesModel;

      final updatedAuthorities = finalAuthorities.copyWith(
        name: 'ROLE_ADMIN',
      );

      expect(finalAuthorities == updatedAuthorities, false);
    });
  });
}
