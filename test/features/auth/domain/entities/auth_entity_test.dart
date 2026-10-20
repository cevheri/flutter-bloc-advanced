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

    // Regression: with stringify on, the default of every debug build, the text printed the password.
    test('toString names the user and leaves the password out', () {
      final text = const AuthCredentialsEntity(username: 'admin', password: 'S3cret!pw').toString();

      expect(text, allOf(startsWith('AuthCredentialsEntity('), contains('admin'), isNot(contains('S3cret!pw'))));
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

    // Regression: with stringify on, the default of every debug build, the text printed both tokens in full.
    test('toString shows only masked previews of the tokens', () {
      const idToken = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.c2lnbmF0dXJl';
      const refreshToken = 'rt-9f8e7d6c5b4a3f2e1d0c';

      final text = const AuthTokenEntity(idToken: idToken, refreshToken: refreshToken).toString();

      expect(text, allOf(startsWith('AuthTokenEntity('), isNot(contains(idToken)), isNot(contains(refreshToken))));
      expect(text, allOf(contains('eyJh…dXJl'), contains('rt-9…1d0c')));
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

    // Regression: with stringify on, the default of every debug build, the text printed the code.
    test('toString names the email and leaves the code out', () {
      final text = const VerifyOtpEntity(email: 'otp.user@example.com', otp: '493817').toString();

      expect(text, allOf(startsWith('VerifyOtpEntity('), contains('otp.user@example.com'), isNot(contains('493817'))));
    });
  });
}
