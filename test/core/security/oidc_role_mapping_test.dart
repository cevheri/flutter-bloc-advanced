import 'package:flutter_bloc_advance/core/security/oidc_role_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Ported one for one from LibreDB Studio's tests/unit/lib/oidc.test.ts, describe("mapOIDCRole").
  group('mapOidcRole (LibreDB Studio cases)', () {
    OidcRole? map(
      Map<String, Object?> claims,
      String? roleClaim,
      List<String> adminRoles, [
      List<String> userRoles = const <String>[],
    ]) => mapOidcRole(claims, roleClaim: roleClaim, adminRoles: adminRoles, userRoles: userRoles);

    test('returns user when roleClaim is empty', () {
      expect(map({'roles': 'admin'}, '', ['admin']), OidcRole.user);
    });

    test('returns user when roleClaim is null', () {
      expect(map({'roles': 'admin'}, null, ['admin']), OidcRole.user);
    });

    test('returns user when claim is missing', () {
      expect(map({}, 'roles', ['admin']), OidcRole.user);
    });

    test('returns admin for flat string claim match', () {
      expect(map({'role': 'admin'}, 'role', ['admin']), OidcRole.admin);
    });

    test('returns user for flat string claim no match', () {
      expect(map({'role': 'viewer'}, 'role', ['admin']), OidcRole.user);
    });

    test('returns admin for array claim match', () {
      final claims = {
        'roles': ['viewer', 'admin', 'editor'],
      };
      expect(map(claims, 'roles', ['admin']), OidcRole.admin);
    });

    test('returns user for array claim no match', () {
      final claims = {
        'roles': ['viewer', 'editor'],
      };
      expect(map(claims, 'roles', ['admin']), OidcRole.user);
    });

    test('supports dot-notation for nested claims', () {
      final claims = {
        'realm_access': {
          'roles': ['admin'],
        },
      };
      expect(map(claims, 'realm_access.roles', ['admin']), OidcRole.admin);
    });

    test('returns user for nested claim path not found', () {
      final claims = {'realm_access': <String, Object?>{}};
      expect(map(claims, 'realm_access.roles', ['admin']), OidcRole.user);
    });

    test('returns user when nested path traverses non-object', () {
      final claims = {'realm_access': 'string'};
      expect(map(claims, 'realm_access.roles', ['admin']), OidcRole.user);
    });

    test('case-insensitive matching', () {
      expect(map({'role': 'Admin'}, 'role', ['admin']), OidcRole.admin);
      expect(map({'role': 'ADMIN'}, 'role', ['admin']), OidcRole.admin);
    });

    test('supports multiple admin role values', () {
      expect(map({'role': 'superadmin'}, 'role', ['admin', 'superadmin']), OidcRole.admin);
      expect(map({'role': 'admin'}, 'role', ['admin', 'superadmin']), OidcRole.admin);
      expect(map({'role': 'viewer'}, 'role', ['admin', 'superadmin']), OidcRole.user);
    });

    test('handles null value in claim path', () {
      final claims = <String, Object?>{'realm_access': null};
      expect(map(claims, 'realm_access.roles', ['admin']), OidcRole.user);
    });

    // An empty userRoles is the rule above: an account that matches no admin role is a user, and nobody is refused.
    test('an empty userRoles maps every non-admin to user and never to null', () {
      final unmatched = <(Map<String, Object?>, String)>[
        ({'roles': 'admin'}, ''),
        ({}, 'roles'),
        ({'role': 'viewer'}, 'role'),
        (
          {
            'roles': ['viewer', 'editor'],
          },
          'roles',
        ),
        ({'realm_access': <String, Object?>{}}, 'realm_access.roles'),
        ({'realm_access': 'string'}, 'realm_access.roles'),
        ({'realm_access': null}, 'realm_access.roles'),
        ({'libredb_roles': <Object?>[]}, 'libredb_roles'),
      ];
      for (final (claims, roleClaim) in unmatched) {
        expect(map(claims, roleClaim, ['admin']), OidcRole.user, reason: '$claims / $roleClaim');
        expect(map(claims, roleClaim, ['admin'], const <String>[]), OidcRole.user, reason: '$claims / $roleClaim');
      }
      expect(
        map(
          {
            'roles': ['viewer', 'admin'],
          },
          'roles',
          ['admin'],
        ),
        OidcRole.admin,
      );
      expect(
        map(
          {
            'roles': ['viewer', 'admin'],
          },
          'roles',
          ['admin'],
          const <String>[],
        ),
        OidcRole.admin,
      );
    });

    test('with userRoles [user], a claim holding only [viewer] maps to null', () {
      expect(
        map(
          {
            'libredb_roles': ['viewer'],
          },
          'libredb_roles',
          ['admin'],
          ['user'],
        ),
        isNull,
      );
    });

    test('with userRoles [user], a claim holding [user] maps to user', () {
      expect(
        map(
          {
            'libredb_roles': ['user'],
          },
          'libredb_roles',
          ['admin'],
          ['user'],
        ),
        OidcRole.user,
      );
      expect(map({'libredb_roles': 'user'}, 'libredb_roles', ['admin'], ['user']), OidcRole.user);
    });

    test('admin wins when the claim holds both the admin and the user role', () {
      expect(
        map(
          {
            'libredb_roles': ['user', 'admin'],
          },
          'libredb_roles',
          ['admin'],
          ['user'],
        ),
        OidcRole.admin,
      );
      expect(
        map(
          {
            'libredb_roles': ['admin', 'user'],
          },
          'libredb_roles',
          ['admin'],
          ['user'],
        ),
        OidcRole.admin,
      );
    });

    test('an admin match needs no user role', () {
      expect(
        map(
          {
            'libredb_roles': ['admin'],
          },
          'libredb_roles',
          ['admin'],
          ['user'],
        ),
        OidcRole.admin,
      );
    });

    test('user roles compare case-insensitively, as admin roles do', () {
      expect(
        map(
          {
            'libredb_roles': ['USER'],
          },
          'libredb_roles',
          ['admin'],
          ['User'],
        ),
        OidcRole.user,
      );
      expect(map({'role': 'Analyst'}, 'role', ['admin'], ['user', 'analyst']), OidcRole.user);
    });

    test('with userRoles set, a claim that is missing, empty or not reachable maps to null', () {
      expect(map({}, 'libredb_roles', ['admin'], ['user']), isNull);
      expect(map({'libredb_roles': <Object?>[]}, 'libredb_roles', ['admin'], ['user']), isNull);
      expect(map({'realm_access': <String, Object?>{}}, 'realm_access.roles', ['admin'], ['user']), isNull);
      expect(map({'realm_access': 'string'}, 'realm_access.roles', ['admin'], ['user']), isNull);
      expect(map({'realm_access': null}, 'realm_access.roles', ['admin'], ['user']), isNull);
    });

    test('with userRoles set and no role claim configured, no account maps to a role', () {
      expect(
        map(
          {
            'roles': ['user'],
          },
          '',
          ['admin'],
          ['user'],
        ),
        isNull,
      );
    });
  });

  group('mapOidcRole (literal keys and object shapes)', () {
    test('a top-level key that contains dots is read as is', () {
      final claims = {
        'https://example.com/roles': ['admin'],
      };
      expect(
        mapOidcRole(claims, roleClaim: 'https://example.com/roles', adminRoles: ['admin'], userRoles: const <String>[]),
        OidcRole.admin,
      );
      expect(
        mapOidcRole(claims, roleClaim: 'https://example.com/roles', adminRoles: ['admin'], userRoles: ['user']),
        OidcRole.admin,
      );
    });

    test('an object value contributes its keys (Zitadel)', () {
      final claims = {
        'urn:zitadel:iam:org:project:roles': {
          'admin': {'1': 'acme.zitadel.cloud'},
        },
      };
      expect(
        mapOidcRole(
          claims,
          roleClaim: 'urn:zitadel:iam:org:project:roles',
          adminRoles: ['admin'],
          userRoles: const <String>[],
        ),
        OidcRole.admin,
      );
    });

    test('an object element of an array contributes its keys (Zitadel, array-wrapped)', () {
      final claims = {
        'urn:zitadel:iam:org:project:roles': [
          {
            'user': {'1': 'x'},
          },
        ],
      };
      expect(
        mapOidcRole(claims, roleClaim: 'urn:zitadel:iam:org:project:roles', adminRoles: ['admin'], userRoles: ['user']),
        OidcRole.user,
      );
    });

    test('a literal top-level key wins over the dot path', () {
      final claims = {
        'a.b': ['admin'],
        'a': {
          'b': ['user'],
        },
      };
      expect(mapOidcRole(claims, roleClaim: 'a.b', adminRoles: ['admin'], userRoles: ['user']), OidcRole.admin);
    });

    test('an object whose keys match nothing stays unmatched', () {
      final claims = {
        'roles': {
          'viewer': {'1': 'x'},
        },
      };
      expect(mapOidcRole(claims, roleClaim: 'roles', adminRoles: ['admin'], userRoles: ['user']), isNull);
      expect(
        mapOidcRole(claims, roleClaim: 'roles', adminRoles: ['admin'], userRoles: const <String>[]),
        OidcRole.user,
      );
    });

    test('a mixed array of strings and objects is matched on both', () {
      final claims = {
        'roles': [
          'viewer',
          {'admin': <String, Object?>{}},
        ],
      };
      expect(mapOidcRole(claims, roleClaim: 'roles', adminRoles: ['admin'], userRoles: ['user']), OidcRole.admin);
    });
  });

  group('appRolesFor', () {
    test('admin holds ROLE_ADMIN and ROLE_USER', () {
      expect(appRolesFor(OidcRole.admin), ['ROLE_ADMIN', 'ROLE_USER']);
    });

    test('user holds ROLE_USER', () {
      expect(appRolesFor(OidcRole.user), ['ROLE_USER']);
    });
  });
}
