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
  });
}
