import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

/// Test the User model
void main() {
  final model = mockUserFullPayload;

  setUp(() {
    initializeJsonMapper();
  });

  group('User Model', () {
    test('should create a User instance (Constructor)', () {
      final finalUser = model;

      expect(finalUser.id, '1');
      expect(finalUser.login, 'test_login');
      expect(finalUser.firstName, 'John');
      expect(finalUser.lastName, 'Doe');
      expect(finalUser.email, 'john.doe@example.com');
      expect(finalUser.activated, true);
      expect(finalUser.langKey, 'en');
      expect(finalUser.createdBy, 'admin');
      expect(finalUser.createdDate, createdDate);
      expect(finalUser.lastModifiedBy, 'admin');
      expect(finalUser.lastModifiedDate, createdDate);
      expect(finalUser.authorities, ['ROLE_USER']);
    });

    test('should copy a User instance with new values (copyWith)', () {
      final finalUser = model;

      final updatedUser = finalUser.copyWith(
        firstName: 'Jane',
        lastName: 'Smith',
      );

      expect(updatedUser.id, '1');
      expect(updatedUser.login, 'test_login');
      expect(updatedUser.firstName, 'Jane');
      expect(updatedUser.lastName, 'Smith');
      expect(updatedUser.email, 'john.doe@example.com');
      expect(updatedUser.activated, true);
      expect(updatedUser.langKey, 'en');
      expect(updatedUser.createdBy, 'admin');
      expect(updatedUser.createdDate, createdDate);
      expect(updatedUser.lastModifiedBy, 'admin');
      expect(updatedUser.lastModifiedDate, createdDate);
      expect(updatedUser.authorities, ['ROLE_USER']);
    });

    test('should deserialize from JSON', () {
      final json = model.toJson();

      final finalUser = User.fromJson(json!);

      expect(finalUser?.id, '1');
      expect(finalUser?.login, 'test_login');
      expect(finalUser?.firstName, 'John');
      expect(finalUser?.lastName, 'Doe');
      expect(finalUser?.email, 'john.doe@example.com');
      expect(finalUser?.activated, true);
      expect(finalUser?.langKey, 'en');
      expect(finalUser?.createdBy, 'admin');
      expect(finalUser?.createdDate, createdDate);
      expect(finalUser?.lastModifiedBy, 'admin');
      expect(finalUser?.lastModifiedDate, createdDate);
      expect(finalUser?.authorities, ['ROLE_USER']);
    });

    test('should deserialize from JSON string', () {
      var jsonString = jsonEncode(model.toJson());

      final finalUser = User.fromJsonString(jsonString);

      expect(finalUser?.id, '1');
      expect(finalUser?.login, 'test_login');
      expect(finalUser?.firstName, 'John');
      expect(finalUser?.lastName, 'Doe');
      expect(finalUser?.email, 'john.doe@example.com');
      expect(finalUser?.activated, true);
      expect(finalUser?.langKey, 'en');
      expect(finalUser?.createdBy, 'admin');
      expect(finalUser?.createdDate, createdDate);
      expect(finalUser?.lastModifiedBy, 'admin');
      expect(finalUser?.lastModifiedDate, createdDate);
      expect(finalUser?.authorities, ['ROLE_USER']);
    });
  });
}
