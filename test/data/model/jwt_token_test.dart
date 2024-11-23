import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/jwt_token.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

///Test the JWTToken model
void main() {
  setUp(() {
    initializeJsonMapper();
  });

  group("JWTToken model", () {
    test('should create a JWTToken instance (Constructor)', () {
      const entity = mockJWTTokenPayload;

      expect(entity.idToken, 'MOCK_TOKEN');
    });

    test('should copy a JWTToken instance with new values (copyWith)', () {
      const entity = mockJWTTokenPayload;
      final entityUpd = entity.copyWith(idToken: 'new_idToken');

      expect(entityUpd.idToken, 'new_idToken');
    });

    test('should copy a JWTToken instance with new values (copyWith)', () {
      const entity = mockJWTTokenPayload;
      final entityUpd = entity.copyWith();

      expect(entityUpd == entity, true);
    });

    test('should compare two JWTToken  instances', () {
      const entity = mockJWTTokenPayload;
      final entityUpd = entity.copyWith(idToken: 'new_idToken');

      expect(entity == entityUpd, false);
    });

    test('should compare two JWTToken copy old values', () {
      const entity = mockJWTTokenPayload;
      final entityUpd = entity.copyWith();

      expect(entity.idToken, entityUpd.idToken);
    });
  });

  //from json
  group('JWTToken from JSON', () {
    test('should deserialize from JSON', () {
      final json = mockJWTTokenPayload.toJson();
      final entity = JWTToken.fromJson(json!);

      expect(entity?.idToken, 'MOCK_TOKEN');
    });

    test('should deserialize from JSON string', () {
      final json = mockJWTTokenPayload.toJson();
      final entity = JWTToken.fromJsonString(jsonEncode(json!));

      expect(entity?.idToken, 'MOCK_TOKEN');
    });
  });

  // toString, equals, hashcode
  group("toString, equals and hashcode", () {
    test('should return string', () {
      const entity = mockJWTTokenPayload;

      expect(entity.toString(), 'JWTToken(MOCK_TOKEN)');
    });

    test('should return true when comparing two JWTToken instances', () {
      const entity = mockJWTTokenPayload;
      final entityUpd = entity.copyWith(idToken: 'new_idToken');

      expect(entity == entityUpd, false);
    });

    test('should return hashcode', () {
      const entity = mockJWTTokenPayload;

      expect(entity.hashCode, entity.idToken.hashCode);
    });
  });
}
