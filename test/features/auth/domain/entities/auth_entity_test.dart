import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthCredentialsEntity', () {
    test('supports value equality', () {
      const a = AuthCredentialsEntity(username: 'admin', password: 'pass');
      const b = AuthCredentialsEntity(username: 'admin', password: 'pass');
      expect(a, b);
    });

    test('different values are not equal', () {
      const a = AuthCredentialsEntity(username: 'admin', password: 'pass');
      const b = AuthCredentialsEntity(username: 'user', password: 'pass');
      expect(a, isNot(b));
    });

    test('props contains username and password', () {
      const entity = AuthCredentialsEntity(username: 'admin', password: 'pass');
      expect(entity.props, ['admin', 'pass']);
    });
  });

  group('AuthTokenEntity', () {
    test('isValid returns true for non-empty token', () {
      const token = AuthTokenEntity(idToken: 'jwt-token');
      expect(token.isValid, true);
    });

    test('isValid returns false for null token', () {
      const token = AuthTokenEntity();
      expect(token.isValid, false);
    });

    test('isValid returns false for empty token', () {
      const token = AuthTokenEntity(idToken: '');
      expect(token.isValid, false);
    });

    test('supports value equality', () {
      const a = AuthTokenEntity(idToken: 'token');
      const b = AuthTokenEntity(idToken: 'token');
      expect(a, b);
    });
  });

  group('SendOtpEntity', () {
    test('supports value equality', () {
      const a = SendOtpEntity(email: 'test@test.com');
      const b = SendOtpEntity(email: 'test@test.com');
      expect(a, b);
    });

    test('props contains email', () {
      const entity = SendOtpEntity(email: 'test@test.com');
      expect(entity.props, ['test@test.com']);
    });
  });

  group('VerifyOtpEntity', () {
    test('supports value equality', () {
      const a = VerifyOtpEntity(email: 'test@test.com', otp: '123456');
      const b = VerifyOtpEntity(email: 'test@test.com', otp: '123456');
      expect(a, b);
    });

    test('different otp values are not equal', () {
      const a = VerifyOtpEntity(email: 'test@test.com', otp: '123456');
      const b = VerifyOtpEntity(email: 'test@test.com', otp: '000000');
      expect(a, isNot(b));
    });
  });
}
