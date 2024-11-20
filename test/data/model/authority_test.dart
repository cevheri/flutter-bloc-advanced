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
      final entityUpd = mockAuthorityPayload.copyWith();

      expect(entityUpd == mockAuthorityPayload, true);
    });

    test('should copy a Authority instance with new values (copyWith)', () {
      final entityUpd = mockAuthorityPayload.copyWith(name: 'ROLE_ADMIN');

      expect(entityUpd.name, 'ROLE_ADMIN');
    });

    test('should compare two Authorities instances', () {
      const entity = mockAuthorityPayload;
      final entityUpd = entity.copyWith(name: 'ROLE_ADMIN');

      expect(entity == entityUpd, false);
    });
  });

  group("Authority Model Json Test", () {
    test('should convert Authorities from Json', () {
      final json = mockAuthorityPayload.toJson();
      final entity = Authority.fromJson(json!);

      expect(entity?.name, 'ROLE_USER');
    });

    test('should convert Authorities from JsonString', () {
      final jsonString = jsonEncode(mockAuthorityPayload.toJson());
      final entity = Authority.fromJsonString(jsonString);

      expect(entity?.name, 'ROLE_USER');
    });

    test('should convert Authorities to Json', () {
      final json = mockAuthorityPayload.toJson()!;

      expect(json['name'], 'ROLE_USER');
    });

    test("to string method", () {
      const entity = mockAuthorityPayload;

      expect(entity.toString(), 'Authority(ROLE_USER)');
    });
  });
}
