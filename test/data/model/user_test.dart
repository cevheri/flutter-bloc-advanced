import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test the User model
void main() {
  final DateTime createdDate = DateTime(2024, 1, 1);
  late User userModel;
  User initUser() {
    return User(
      id: '1',
      login: 'test_login',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      activated: true,
      langKey: 'en',
      createdBy: 'admin',
      createdDate: createdDate,
      lastModifiedBy: 'admin',
      lastModifiedDate: createdDate,
      authorities: const ['ROLE_USER'],
    );
  }

  // Initialize Test
  setUp(() {
    initializeJsonMapper();

    userModel = initUser();
  });

  group('User Model', () {
    test('should create a User instance (Constructor)', () {
      final finalUser = userModel;

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
      final finalUser = userModel;

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
      final createdDateString = createdDate.toIso8601String();
      final json = {
        'id': '1',
        'login': 'test_login',
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john.doe@example.com',
        'activated': true,
        'langKey': 'en',
        'createdBy': 'admin',
        'createdDate': createdDateString,
        'lastModifiedBy': 'admin',
        'lastModifiedDate': createdDateString,
        'authorities': ['ROLE_USER'],
      };

      final finalUser = User.fromJson(json);

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
      //postUserJson = await rootBundle.loadString(mockDataPath+postUserMockData);

      final createdDateString = createdDate.toIso8601String();
      final jsonString = '''
      {
        "id": "1",
        "login": "test_login",
        "firstName": "John",
        "lastName": "Doe",
        "email": "john.doe@example.com",
        "activated": true,
        "langKey": "en",
        "createdBy": "admin",
        "createdDate": "$createdDateString",
        "lastModifiedBy": "admin",
        "lastModifiedDate": "$createdDateString",
        "authorities": ["ROLE_USER"]
      }
      ''';

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
