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
      final finalJWTToken = mockJWTTokenPayload;
      expect(finalJWTToken.idToken, 'MOCK_UNITTEST_TOKEN');
    });

    test('should copy a JWTToken instance with new values (copyWith)', () {
      final finalJWTToken = mockJWTTokenPayload;
      final updatedJWTToken = finalJWTToken.copyWith(
        idToken: 'new_idToken',
      );
      expect(updatedJWTToken.idToken, 'new_idToken');
    });

    test('should copy a JWTToken instance with new values (copyWith)', () {
      final finalJWTToken = mockJWTTokenPayload;
      final updatedJWTToken = finalJWTToken.copyWith();
      expect(updatedJWTToken == finalJWTToken, true);
    });

    test('should compare two JWTToken  instances', () {
      final finalJWTToken = mockJWTTokenPayload;
      final updatedJWTToken = finalJWTToken.copyWith(
        idToken: 'new_idToken',
      );
      expect(finalJWTToken == updatedJWTToken, false);
    });

    test('should compare two JWTToken copy old values', () {
      final finalJWTToken = mockJWTTokenPayload;
      final updatedJWTToken = finalJWTToken.copyWith();
      expect(finalJWTToken.idToken, updatedJWTToken.idToken);
    });
  });

  //from json
  group('JWTToken from JSON', () {
    test('should deserialize from JSON', () {
      final json = mockJWTTokenPayload.toJson();
      final jwtToken = JWTToken.fromJson(json!);
      expect(jwtToken?.idToken, 'MOCK_UNITTEST_TOKEN');
    });

    test('should deserialize from JSON string', () {
      final json = mockJWTTokenPayload.toJson();
      final jwtToken = JWTToken.fromJsonString(jsonEncode(json!));
      expect(jwtToken?.idToken, 'MOCK_UNITTEST_TOKEN');
    });
  });

  // toString, equals, hashcode
  group("toString, equals and hashcode", (){
    test('should return string', () {
      final finalJWTToken = mockJWTTokenPayload;
      expect(finalJWTToken.toString(), 'JWTToken(MOCK_UNITTEST_TOKEN)');
    });

    test('should return true when comparing two JWTToken instances', () {
      final finalJWTToken = mockJWTTokenPayload;
      final updatedJWTToken = finalJWTToken.copyWith(
        idToken: 'new_idToken',
      );
      expect(finalJWTToken == updatedJWTToken, false);
    });

    test('should return hashcode', () {
      final finalJWTToken = mockJWTTokenPayload;
      expect(finalJWTToken.hashCode, finalJWTToken.idToken.hashCode);
    });
  });
}
