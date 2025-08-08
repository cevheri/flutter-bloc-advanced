import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

/// Test the User model
void main() {
  setUp(() {
    initializeJsonMapper();
  });

  group('User Model', () {
    test('should create a User instance (Constructor)', () {
      final entity = mockUserFullPayload;

      expect(entity.id, '1');
      expect(entity.login, 'test_login');
      expect(entity.firstName, 'John');
      expect(entity.lastName, 'Doe');
      expect(entity.email, 'john.doe@example.com');
      expect(entity.activated, true);
      expect(entity.langKey, 'en');
      expect(entity.createdBy, 'admin');
      expect(entity.createdDate, createdDate);
      expect(entity.lastModifiedBy, 'admin');
      expect(entity.lastModifiedDate, createdDate);
      expect(entity.authorities, ['ROLE_USER']);
    });

    test('should copy a User instance with new values (copyWith)', () {
      final entity = mockUserFullPayload;
      final entityUpd = entity.copyWith();

      expect(entityUpd.id, '1');
      expect(entityUpd.login, 'test_login');
      expect(entityUpd.firstName, 'John');
      expect(entityUpd.lastName, 'Doe');
      expect(entityUpd.email, 'john.doe@example.com');
      expect(entityUpd.activated, true);
      expect(entityUpd.langKey, 'en');
      expect(entityUpd.createdBy, 'admin');
      expect(entityUpd.createdDate, createdDate);
      expect(entityUpd.lastModifiedBy, 'admin');
      expect(entityUpd.lastModifiedDate, createdDate);
      expect(entityUpd.authorities, ['ROLE_USER']);
    });

    test('should copy a User instance with new values copyWith fistName', () {
      final entity = mockUserFullPayload;
      final entityUpd = entity.copyWith(firstName: 'Jane');

      expect(entityUpd.firstName, 'Jane');
    });

    test('should copy a User instance with new values copyWith lastname', () {
      final entity = mockUserFullPayload;
      final entityUpd = entity.copyWith(lastName: 'Smith');

      expect(entityUpd.lastName, 'Smith');
    });

    test('should deserialize from JSON', () {
      final json = mockUserFullPayload.toJson();
      final entity = User.fromJson(json!);

      expect(entity?.id, '1');
      expect(entity?.login, 'test_login');
      expect(entity?.firstName, 'John');
      expect(entity?.lastName, 'Doe');
      expect(entity?.email, 'john.doe@example.com');
      expect(entity?.activated, true);
      expect(entity?.langKey, 'en');
      expect(entity?.createdBy, 'admin');
      expect(entity?.createdDate, createdDate);
      expect(entity?.lastModifiedBy, 'admin');
      expect(entity?.lastModifiedDate, createdDate);
      expect(entity?.authorities, ['ROLE_USER']);
    });

    test('should deserialize from JSON string', () {
      final jsonString = jsonEncode(mockUserFullPayload.toJson());
      final entity = User.fromJsonString(jsonString);

      expect(entity?.id, '1');
      expect(entity?.login, 'test_login');
      expect(entity?.firstName, 'John');
      expect(entity?.lastName, 'Doe');
      expect(entity?.email, 'john.doe@example.com');
      expect(entity?.activated, true);
      expect(entity?.langKey, 'en');
      expect(entity?.createdBy, 'admin');
      expect(entity?.createdDate, createdDate);
      expect(entity?.lastModifiedBy, 'admin');
      expect(entity?.lastModifiedDate, createdDate);
      expect(entity?.authorities, ['ROLE_USER']);
    });
  });
}
