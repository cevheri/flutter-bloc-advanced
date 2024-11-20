import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/authority.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

/// Test the Authority model
void main() {
  setUp(() {
    initializeJsonMapper();
  });

  group("Authority Model", () {
    test('should create a Authority instance (Constructor)', () {
      expect(mockAuthorityPayload.name, 'ROLE_USER');
    });

    test('should copy a Authority instance with new values (copyWith)', () {
      final updatedAuthority = mockAuthorityPayload.copyWith();

      expect(updatedAuthority == mockAuthorityPayload, true);
    });

    test('should copy a Authority instance with new values (copyWith)', () {
      final updatedAuthority = mockAuthorityPayload.copyWith(
        name: 'ROLE_ADMIN',
      );

      expect(updatedAuthority.name, 'ROLE_ADMIN');
    });

    test('should compare two Authorities instances', () {
      final finalAuthority = mockAuthorityPayload;

      final updatedAuthority = finalAuthority.copyWith(
        name: 'ROLE_ADMIN',
      );

      expect(finalAuthority == updatedAuthority, false);
    });
  });

  group("Authority Model Json Test", () {
    test('should convert Authorities from Json', () {
      final json = mockAuthorityPayload.toJson();

      final authority = Authority.fromJson(json!);

      expect(authority?.name, 'ROLE_USER');
    });

    test('should convert Authorities from JsonString', () {
      final jsonString = jsonEncode(mockAuthorityPayload.toJson());

      final authority = Authority.fromJsonString(jsonString);

      expect(authority?.name, 'ROLE_USER');
    });

    test('should convert Authorities to Json', () {
      final json = mockAuthorityPayload.toJson()!;

      expect(json['name'], 'ROLE_USER');
    });

    test("to string method", () {
      final authority = mockAuthorityPayload;

      expect(authority.toString(), 'Authority(ROLE_USER)');
    });
  });
}
