import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/user_jwt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';
import '../../test_utils.dart';

void main() {
  setUp(() async {
    TestUtils().setupUnitTest();
  });

  // model test, constructor, copyWith, toJson, fromJson, props, toString, equals, hashcode
  group("UserJWT Model", () {
    test('should create a UserJWT instance (Constructor)', () {
      final finalUserJWT = userJWTMockPayload;

      expect(finalUserJWT.username, 'username');
      expect(finalUserJWT.password, 'password');
    });

    test('should copy a UserJWT instance with new values (copyWith)', () {
      final finalUserJWT = userJWTMockPayload;
      final updatedUserJWT = finalUserJWT.copyWith();

      expect(updatedUserJWT == finalUserJWT, true);
    });

    test('should copy a UserJWT instance with new values (copyWith) username', () {
      final finalUserJWT = userJWTMockPayload;
      final updatedUserJWT = finalUserJWT.copyWith(username: 'new_username');

      expect(updatedUserJWT.username, 'new_username');
    });
    test('should copy a UserJWT instance with new values (copyWith) pass', () {
      final finalUserJWT = userJWTMockPayload;
      final updatedUserJWT = finalUserJWT.copyWith(password: 'new_password');

      expect(updatedUserJWT.password, 'new_password');
    });

    test('should deserialize from JSON', () {
      final json = userJWTMockPayload.toJson();

      final userJWT = UserJWT.fromJson(json!);

      expect(userJWT?.username, 'username');
      expect(userJWT?.password, 'password');
    });

    test('should deserialize from JSON string', () {
      final json = userJWTMockPayload.toJson();
      final userJWT = UserJWT.fromJsonString(jsonEncode(json!));

      expect(userJWT?.username, 'username');
      expect(userJWT?.password, 'password');
    });

    test('should serialize to JSON', () {
      final userJWT = userJWTMockPayload;

      final json = userJWT.toJson()!;

      expect(json['username'], 'username');
      expect(json['password'], 'password');
    });

    // props, toString, equals, hashcode
    test("props should return list of properties", () {
      final userJWT = userJWTMockPayload;

      expect(userJWT.props, [userJWT.username, userJWT.password]);
    });

    test('toString should return string', () {
      final userJWT = userJWTMockPayload;

      expect(userJWT.toString(), 'UserJWT{password: password}');
    });

    test('should return true when comparing two UserJWT instances', () {
      final userJWT = userJWTMockPayload;
      final updatedUserJWT = userJWT.copyWith(
        username: 'new_username',
        password: 'new_password',
      );

      expect(userJWT == updatedUserJWT, false);
    });

    test("hashCode should return hash code", () {
      final userJWT = userJWTMockPayload;
      final updatedUserJWT = userJWT.copyWith(
        username: 'new_username',
        password: 'new_password',
      );

      expect(userJWT.hashCode == updatedUserJWT.hashCode, false);
    });
  });
}
