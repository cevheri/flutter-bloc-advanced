import 'dart:convert';

import 'package:flutter_bloc_advance/features/auth/data/models/jwt_token.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/fake_data.dart';

///Test the JWTToken model
void main() {
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

      expect(entity.idToken, 'MOCK_TOKEN');
    });

    test('should deserialize from JSON string', () {
      final json = mockJWTTokenPayload.toJson();
      final entity = JWTToken.fromJsonString(jsonEncode(json!));

      expect(entity.idToken, 'MOCK_TOKEN');
    });
  });

  // toString, equals, hashcode
  group("toString, equals and hashcode", () {
    test('toString masks tokens — raw idToken/refreshToken must not appear', () {
      const entity = JWTToken(
        idToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature',
        refreshToken: 'refresh-token-secret-value-12345',
      );

      final rendered = entity.toString();

      expect(rendered, isNot(contains('payload')));
      expect(rendered, isNot(contains('signature')));
      expect(rendered, isNot(contains('refresh-token-secret-value-12345')));
      expect(rendered, startsWith('JWTToken('));
    });

    test('should return true when comparing two JWTToken instances', () {
      const entity = mockJWTTokenPayload;
      final entityUpd = entity.copyWith(idToken: 'new_idToken');

      expect(entity == entityUpd, false);
    });

    test('should return hashcode', () {
      const entity = mockJWTTokenPayload;

      expect(entity.hashCode, Object.hash(entity.idToken, entity.refreshToken));
    });
  });
}
