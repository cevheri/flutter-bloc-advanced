import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';

abstract class IAuthRepository {
  Future<AuthTokenEntity?> authenticate(AuthCredentialsEntity userJWT);

  Future<void> logout();

  Future<void> sendOtp(SendOtpEntity request);

  Future<AuthTokenEntity?> verifyOtp(VerifyOtpEntity request);
}
