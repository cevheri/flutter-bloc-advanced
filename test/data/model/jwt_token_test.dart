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
      final finalJWTToken = jWTTokenMockPayload;
      expect(finalJWTToken.idToken, 'idToken');
    });

    test('should copy a JWTToken instance with new values (copyWith)', () {
      final finalJWTToken = jWTTokenMockPayload;
      final updatedJWTToken = finalJWTToken.copyWith(
        idToken: 'new_idToken',
      );
      expect(updatedJWTToken.idToken, 'new_idToken');
    });

    test('should copy a JWTToken instance with new values (copyWith)', () {
      final finalJWTToken = jWTTokenMockPayload;
      final updatedJWTToken = finalJWTToken.copyWith();
      expect(updatedJWTToken == finalJWTToken, true);
    });

    test('should compare two JWTToken  instances', () {
      final finalJWTToken = jWTTokenMockPayload;
      final updatedJWTToken = finalJWTToken.copyWith(
        idToken: 'new_idToken',
      );
      expect(finalJWTToken == updatedJWTToken, false);
    });

    test('should compare two JWTToken copy old values', () {
      final finalJWTToken = jWTTokenMockPayload;
      final updatedJWTToken = finalJWTToken.copyWith();
      expect(finalJWTToken.idToken, updatedJWTToken.idToken);
    });
  });

  //from json
  group('JWTToken from JSON', () {
    test('should deserialize from JSON', () {
      final json = jWTTokenMockPayload.toJson();
      final jwtToken = JWTToken.fromJson(json!);
      expect(jwtToken?.idToken, 'idToken');
    });

    test('should deserialize from JSON string', () {
      final json = jWTTokenMockPayload.toJson();
      final jwtToken = JWTToken.fromJsonString(jsonEncode(json!));
      expect(jwtToken?.idToken, 'idToken');
    });
  });

  // toString, equals, hashcode
  group("toString, equals and hashcode", (){
    test('should return string', () {
      final finalJWTToken = jWTTokenMockPayload;
      expect(finalJWTToken.toString(), 'JWTToken{idToken: idToken}');
    });

    test('should return true when comparing two JWTToken instances', () {
      final finalJWTToken = jWTTokenMockPayload;
      final updatedJWTToken = finalJWTToken.copyWith(
        idToken: 'new_idToken',
      );
      expect(finalJWTToken == updatedJWTToken, false);
    });

    test('should return hashcode', () {
      final finalJWTToken = jWTTokenMockPayload;
      expect(finalJWTToken.hashCode, finalJWTToken.idToken.hashCode);
    });
  });
}
