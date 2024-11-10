import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late User userModel;
  // late String postUserJson;
  // final mockDataPath = 'mock/';
  // final postUserMockData = 'POST_admin_users.json';
  // Initialize Test
  setUp(() {
    initializeJsonMapper();

    userModel = User(
      id: '1',
      login: 'test_login',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      activated: true,
      langKey: 'en',
      createdBy: 'admin',
      createdDate: DateTime(2021, 1, 1),
      lastModifiedBy: 'admin',
      lastModifiedDate: DateTime(2021, 1, 2),
      authorities: ['ROLE_USER'],
    );
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
      expect(finalUser.createdDate, DateTime(2021, 1, 1));
      expect(finalUser.lastModifiedBy, 'admin');
      expect(finalUser.lastModifiedDate, DateTime(2021, 1, 2));
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
      expect(updatedUser.createdDate, DateTime(2021, 1, 1));
      expect(updatedUser.lastModifiedBy, 'admin');
      expect(updatedUser.lastModifiedDate, DateTime(2021, 1, 2));
      expect(updatedUser.authorities, ['ROLE_USER']);
    });

    test('should deserialize from JSON', () {
      const json = {
        'id': '1',
        'login': 'test_login',
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john.doe@example.com',
        'activated': true,
        'langKey': 'en',
        'createdBy': 'admin',
        'createdDate': '2021-01-01T00:00:00.000Z',
        'lastModifiedBy': 'admin',
        'lastModifiedDate': '2021-01-02T00:00:00.000Z',
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
      expect(finalUser?.createdDate, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(finalUser?.lastModifiedBy, 'admin');
      expect(finalUser?.lastModifiedDate, DateTime.parse('2021-01-02T00:00:00.000Z'));
      expect(finalUser?.authorities, ['ROLE_USER']);
    });

    test('should deserialize from JSON string', () {
      //postUserJson = await rootBundle.loadString(mockDataPath+postUserMockData);

      const jsonString = '''
      {
        "id": "1",
        "login": "test_login",
        "firstName": "John",
        "lastName": "Doe",
        "email": "john.doe@example.com",
        "activated": true,
        "langKey": "en",
        "createdBy": "admin",
        "createdDate": "2021-01-01T00:00:00.000Z",
        "lastModifiedBy": "admin",
        "lastModifiedDate": "2021-01-02T00:00:00.000Z",
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
      expect(finalUser?.createdDate, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(finalUser?.lastModifiedBy, 'admin');
      expect(finalUser?.lastModifiedDate, DateTime.parse('2021-01-02T00:00:00.000Z'));
      expect(finalUser?.authorities, ['ROLE_USER']);
    });
  });
}
