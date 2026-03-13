import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';

abstract class IAuthRepository {
  Future<Result<AuthTokenEntity>> authenticate(AuthCredentialsEntity userJWT);

  Future<Result<void>> logout();

  Future<Result<void>> sendOtp(SendOtpEntity request);

  Future<Result<AuthTokenEntity>> verifyOtp(VerifyOtpEntity request);
}
