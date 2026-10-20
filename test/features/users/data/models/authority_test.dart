import 'package:flutter_bloc_advance/features/users/data/models/authority.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/fake_data.dart';

/// Test the Authority model
void main() {
  group("Authority Model", () {
    test('should create a Authority instance (Constructor)', () {
      expect(mockAuthorityPayload.name, 'ROLE_USER');
    });

    test('should compare two Authorities instances', () {
      expect(mockAuthorityPayload == const Authority(name: 'ROLE_USER'), true);
      expect(mockAuthorityPayload == const Authority(name: 'ROLE_ADMIN'), false);
    });
  });

  group("Authority Model Json Test", () {
    test('should convert Authorities from Json', () {
      final entity = Authority.fromJson({'name': 'ROLE_USER'});

      expect(entity, mockAuthorityPayload);
    });

    test('should return null from Json without a name', () {
      expect(Authority.fromJson(<String, dynamic>{}), isNull);
    });

    test('should convert a Json list to authority names', () {
      final names = Authority.fromJsonList([
        {'name': 'ROLE_USER'},
        {'name': 'ROLE_ADMIN'},
      ]);

      expect(names, ['ROLE_USER', 'ROLE_ADMIN']);
    });

    test('should convert a Json string list to authority names', () {
      final names = Authority.fromJsonStringList('[{"name": "ROLE_USER"}, {"name": "ROLE_ADMIN"}]');

      expect(names, ['ROLE_USER', 'ROLE_ADMIN']);
    });

    test("to string method", () {
      const entity = mockAuthorityPayload;

      expect(entity.toString(), 'Authority(ROLE_USER)');
    });
  });
}
