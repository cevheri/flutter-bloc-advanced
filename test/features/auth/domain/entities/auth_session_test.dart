import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession.toString', () {
    test('masks idToken and refreshToken', () {
      const session = AuthSession(
        idToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature',
        refreshToken: 'refresh-token-value-12345',
        username: 'alice',
        roles: ['ROLE_USER'],
      );

      final rendered = session.toString();

      expect(rendered.contains('payload'), isFalse);
      expect(rendered.contains('refresh-token-value-12345'), isFalse);
      expect(rendered, contains('alice'));
      expect(rendered, contains('ROLE_USER'));
    });

    test('renders empty marker when refreshToken is null', () {
      const session = AuthSession(idToken: 'eyJhbGc.payload.signature', username: 'alice');
      expect(session.toString(), contains('refreshToken: <empty>'));
    });

    test('masks the OIDC ID token and prints the access token expiry', () {
      final session = AuthSession(
        idToken: 'access-token-value-12345',
        username: 'alice',
        oidcIdToken: 'eyJhbGciOiJSUzI1NiJ9.oidc-payload.oidc-signature',
        accessTokenExpiresAt: DateTime.utc(2026, 10, 21, 12),
      );

      final rendered = session.toString();

      expect(rendered.contains('oidc-payload'), isFalse);
      expect(rendered, contains('oidcIdToken: ${maskToken('eyJhbGciOiJSUzI1NiJ9.oidc-payload.oidc-signature')}'));
      expect(rendered, contains('accessTokenExpiresAt: 2026-10-21 12:00:00.000Z'));
    });

    // A jwt session never carries the OIDC fields, and its logs print it as they did before the fields existed.
    test('prints a session without the OIDC fields as it did before they existed', () {
      const session = AuthSession(
        idToken: 'eyJhbGc.payload.signature',
        refreshToken: 'refresh-token-value-12345',
        username: 'alice',
        roles: ['ROLE_USER'],
      );

      expect(
        session.toString(),
        'AuthSession(idToken: eyJh…ture, refreshToken: refr…2345, username: alice, roles: [ROLE_USER])',
      );
    });

    test('prints only the OIDC field that is set', () {
      expect(
        const AuthSession(
          idToken: 'eyJhbGc.payload.signature',
          username: 'alice',
          oidcIdToken: 'oidc-id-token-value',
        ).toString(),
        'AuthSession(idToken: eyJh…ture, refreshToken: <empty>, username: alice, roles: [], oidcIdToken: oidc…alue)',
      );
      expect(
        AuthSession(
          idToken: 'eyJhbGc.payload.signature',
          username: 'alice',
          accessTokenExpiresAt: DateTime.utc(2026, 10, 21, 12),
        ).toString(),
        'AuthSession(idToken: eyJh…ture, refreshToken: <empty>, username: alice, roles: [], '
        'accessTokenExpiresAt: 2026-10-21 12:00:00.000Z)',
      );
    });
  });

  group('AuthSession equality', () {
    final expiresAt = DateTime.utc(2026, 10, 21, 12);

    test('sessions with the same OIDC ID token and expiry are equal', () {
      expect(
        AuthSession(idToken: 'T', username: 'alice', oidcIdToken: 'ID', accessTokenExpiresAt: expiresAt),
        AuthSession(idToken: 'T', username: 'alice', oidcIdToken: 'ID', accessTokenExpiresAt: expiresAt),
      );
    });

    test('a different OIDC ID token makes a different session', () {
      expect(
        const AuthSession(idToken: 'T', username: 'alice', oidcIdToken: 'ID'),
        isNot(const AuthSession(idToken: 'T', username: 'alice', oidcIdToken: 'OTHER')),
      );
    });

    test('a different access token expiry makes a different session', () {
      expect(
        AuthSession(idToken: 'T', username: 'alice', accessTokenExpiresAt: expiresAt),
        isNot(
          AuthSession(idToken: 'T', username: 'alice', accessTokenExpiresAt: expiresAt.add(const Duration(seconds: 1))),
        ),
      );
    });

    test('the OIDC fields default to null', () {
      const session = AuthSession(idToken: 'T', username: 'alice');

      expect(session.oidcIdToken, isNull);
      expect(session.accessTokenExpiresAt, isNull);
    });
  });
}
