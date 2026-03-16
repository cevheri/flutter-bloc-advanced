import 'package:flutter_bloc_advance/core/security/security_utils.dart';
import 'package:flutter_bloc_advance/features/auth/data/models/jwt_token.dart';
import 'package:flutter_bloc_advance/features/auth/data/models/send_otp_request.dart';
import 'package:flutter_bloc_advance/features/auth/data/models/user_jwt.dart';
import 'package:flutter_bloc_advance/features/auth/data/models/verify_otp_request.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';

class AuthMapper {
  const AuthMapper._();

  static UserJWT toUserJwt(AuthCredentialsEntity entity) {
    return UserJWT(entity.username, entity.password);
  }

  static SendOtpRequest toSendOtpRequest(SendOtpEntity entity) {
    return SendOtpRequest(email: entity.email);
  }

  static VerifyOtpRequest toVerifyOtpRequest(VerifyOtpEntity entity) {
    return VerifyOtpRequest(email: entity.email, otp: entity.otp);
  }

  static AuthTokenEntity? toTokenEntity(JWTToken? model) {
    if (model == null) return null;

    DateTime? expiresAt;
    if (model.idToken != null) {
      expiresAt = SecurityUtils.getTokenExpiration(model.idToken!);
    }

    return AuthTokenEntity(idToken: model.idToken, refreshToken: model.refreshToken, expiresAt: expiresAt);
  }
}
