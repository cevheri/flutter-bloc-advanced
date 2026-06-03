import 'package:flutter_bloc_advance/features/auth/data/mappers/auth_mapper.dart';
import 'package:flutter_bloc_advance/features/auth/data/models/jwt_token.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthMapper', () {
    test('toUserJwt maps credentials to UserJWT', () {
      const credentials = AuthCredentialsEntity(username: 'admin', password: 'pass');
      final result = AuthMapper.toUserJwt(credentials);
      expect(result.username, 'admin');
      expect(result.password, 'pass');
    });

    test('toSendOtpRequest maps entity to request', () {
      const entity = SendOtpEntity(email: 'test@test.com');
      final result = AuthMapper.toSendOtpRequest(entity);
      expect(result.email, 'test@test.com');
    });

    test('toVerifyOtpRequest maps entity to request', () {
      const entity = VerifyOtpEntity(email: 'test@test.com', otp: '123456');
      final result = AuthMapper.toVerifyOtpRequest(entity);
      expect(result.email, 'test@test.com');
      expect(result.otp, '123456');
    });

    test('toTokenEntity maps JWTToken to AuthTokenEntity', () {
      const token = JWTToken(idToken: 'jwt-token');
      final result = AuthMapper.toTokenEntity(token);
      expect(result, isNotNull);
      expect(result!.idToken, 'jwt-token');
    });

    test('toTokenEntity returns null for null input', () {
      final result = AuthMapper.toTokenEntity(null);
      expect(result, isNull);
    });
  });
}
