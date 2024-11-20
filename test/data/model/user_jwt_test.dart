import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/user_jwt.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

void main() {
  setUp(() {
    initializeJsonMapper();
  });

  // model test, constructor, copyWith, toJson, fromJson, props, toString, equals, hashcode
  group("UserJWT Model", () {
    test('should create a UserJWT instance (Constructor)', () {
      const entity = mockUserJWTPayload;

      expect(entity.username, 'username');
      expect(entity.password, 'password');
    });

    test('should copy a UserJWT instance with new values (copyWith)', () {
      const entity = mockUserJWTPayload;
      final entityUpd = entity.copyWith();

      expect(entityUpd == entity, true);
    });

    test('should copy a UserJWT instance with new values (copyWith) username', () {
      const entity = mockUserJWTPayload;
      final entityUpd = entity.copyWith(username: 'new_username');

      expect(entityUpd.username, 'new_username');
    });
    test('should copy a UserJWT instance with new values (copyWith) pass', () {
      const entity = mockUserJWTPayload;
      final entityUpd = entity.copyWith(password: 'new_password');

      expect(entityUpd.password, 'new_password');
    });

    test('should deserialize from JSON', () {
      final json = mockUserJWTPayload.toJson();
      final entity = UserJWT.fromJson(json!);

      expect(entity?.username, 'username');
      expect(entity?.password, 'password');
    });

    test('should deserialize from JSON string', () {
      final json = mockUserJWTPayload.toJson();
      final entity = UserJWT.fromJsonString(jsonEncode(json!));

      expect(entity?.username, 'username');
      expect(entity?.password, 'password');
    });

    test('should serialize to JSON', () {
      const entity = mockUserJWTPayload;
      final json = entity.toJson()!;

      expect(json['username'], 'username');
      expect(json['password'], 'password');
    });

    // props, toString, equals, hashcode
    test("props should return list of properties", () {
      const entity = mockUserJWTPayload;

      expect(entity.props, [entity.username, entity.password]);
    });

    test('toString should return string', () {
      const entity = mockUserJWTPayload;

      expect(entity.toString(), 'UserJWT(username, password)');
    });

    test('should return true when comparing two UserJWT instances', () {
      const entity = mockUserJWTPayload;
      final entityUpd = entity.copyWith(username: 'new_username', password: 'new_password');

      expect(entity == entityUpd, false);
    });

    test("hashCode should return hash code", () {
      const entity = mockUserJWTPayload;
      final entityUpd = entity.copyWith(username: 'new_username', password: 'new_password');

      expect(entity.hashCode == entityUpd.hashCode, false);
    });
  });
}
