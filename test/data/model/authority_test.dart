import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/authorities.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

/// Test the Authorities model
void main() {
  setUp(() {
    initializeJsonMapper();
  });

  group("Authorities Model", () {
    test('should create a Authorities instance (Constructor)', () {
      expect(mockAuthorityPayload.name, 'ROLE_USER');
    });

    test('should copy a Authorities instance with new values (copyWith)', () {
      final updatedAuthorities = mockAuthorityPayload.copyWith();

      expect(updatedAuthorities == mockAuthorityPayload, true);
    });

    test('should copy a Authorities instance with new values (copyWith)', () {
      final updatedAuthorities = mockAuthorityPayload.copyWith(
        name: 'ROLE_ADMIN',
      );

      expect(updatedAuthorities.name, 'ROLE_ADMIN');
    });

    test('should compare two Authorities instances', () {
      final finalAuthorities = mockAuthorityPayload;

      final updatedAuthorities = finalAuthorities.copyWith(
        name: 'ROLE_ADMIN',
      );

      expect(finalAuthorities == updatedAuthorities, false);
    });
  });

  group("Authority Model Json Test", () {
    test('should convert Authorities from Json', () {
      final json = mockAuthorityPayload.toJson();

      final authority = Authorities.fromJson(json!);

      expect(authority?.name, 'ROLE_USER');
    });

    test('should convert Authorities from JsonString', () {
      final jsonString = jsonEncode(mockAuthorityPayload.toJson());

      final authority = Authorities.fromJsonString(jsonString);

      expect(authority?.name, 'ROLE_USER');
    });

    test('should convert Authorities to Json', () {
      final json = mockAuthorityPayload.toJson()!;

      expect(json['name'], 'ROLE_USER');
    });

    test("to string method", () {
      final authority = mockAuthorityPayload;

      expect(authority.toString(), 'Authorities(ROLE_USER)');
    });
  });
}
