import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserEntity', () {
    const entity = UserEntity(
      id: '1',
      login: 'admin',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@test.com',
      activated: true,
      langKey: 'en',
      authorities: ['ROLE_USER'],
    );

    test('supports value equality', () {
      const entity2 = UserEntity(
        id: '1',
        login: 'admin',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@test.com',
        activated: true,
        langKey: 'en',
        authorities: ['ROLE_USER'],
      );
      expect(entity, entity2);
    });

    test('different id means not equal', () {
      final other = entity.copyWith(id: '2');
      expect(entity, isNot(other));
    });

    test('copyWith preserves unchanged fields', () {
      final copied = entity.copyWith(firstName: 'Jane');
      expect(copied.id, '1');
      expect(copied.login, 'admin');
      expect(copied.firstName, 'Jane');
      expect(copied.lastName, 'Doe');
      expect(copied.email, 'john@test.com');
    });

    test('copyWith replaces all fields', () {
      final now = DateTime.now();
      final copied = entity.copyWith(
        id: '2',
        login: 'user',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@test.com',
        activated: false,
        langKey: 'tr',
        createdBy: 'system',
        createdDate: now,
        lastModifiedBy: 'system',
        lastModifiedDate: now,
        authorities: ['ROLE_ADMIN'],
      );
      expect(copied.id, '2');
      expect(copied.login, 'user');
      expect(copied.firstName, 'Jane');
      expect(copied.lastName, 'Smith');
      expect(copied.email, 'jane@test.com');
      expect(copied.activated, false);
      expect(copied.langKey, 'tr');
      expect(copied.createdBy, 'system');
      expect(copied.createdDate, now);
      expect(copied.lastModifiedBy, 'system');
      expect(copied.lastModifiedDate, now);
      expect(copied.authorities, ['ROLE_ADMIN']);
    });

    test('default constructor allows all nulls', () {
      const empty = UserEntity();
      expect(empty.id, isNull);
      expect(empty.login, isNull);
      expect(empty.firstName, isNull);
      expect(empty.email, isNull);
      expect(empty.authorities, isNull);
    });

    test('props includes all fields', () {
      expect(entity.props.length, 12);
    });
  });
}
