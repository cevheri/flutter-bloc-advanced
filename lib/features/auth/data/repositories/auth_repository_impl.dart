import 'dart:io';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/infrastructure/http/http_utils.dart';
import 'package:flutter_bloc_advance/features/auth/data/mappers/auth_mapper.dart';
import 'package:flutter_bloc_advance/features/auth/data/models/jwt_token.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';

class LoginRepository implements IAuthRepository {
  static final _log = AppLogger.getLogger("LoginRepository");

  LoginRepository();

  @override
  Future<AuthTokenEntity?> authenticate(AuthCredentialsEntity userJWT) async {
    _log.debug("BEGIN:authenticate repository start username: {}", [userJWT.username]);
    if (userJWT.username.isEmpty || userJWT.password.isEmpty) {
      throw BadRequestException("Invalid username or password");
    }

    final request = AuthMapper.toUserJwt(userJWT);
    final response = await HttpUtils.postRequest("/authenticate", request);
    final result = JWTToken.fromJsonString(response.body);
    _log.debug("END:authenticate successful - response.body: {}", [result.toString()]);
    return AuthMapper.toTokenEntity(result);
  }

  @override
  Future<void> logout() async {
    _log.debug("BEGIN:logout repository start");
    await AppLocalStorage().clear();
    _log.debug("END:logout successful");
  }

  @override
  Future<void> sendOtp(SendOtpEntity request) async {
    _log.debug("BEGIN:sendOtp repository start email: {}", [request.email]);
    if (request.email.isEmpty) {
      throw BadRequestException("Invalid email");
    }
    final headers = {"Content-Type": "application/json"};
    final response = await HttpUtils.postRequest(
      "/authenticate/send-otp",
      AuthMapper.toSendOtpRequest(request),
      headers: headers,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw BadRequestException(response.body);
    }
    _log.debug("successful response: {}", [response.body]);
    _log.debug("END:sendOtp successful");
  }

  @override
  Future<AuthTokenEntity?> verifyOtp(VerifyOtpEntity request) async {
    _log.debug("BEGIN:verifyOtp repository start email: {}", [request.email]);
    if (request.email.isEmpty || request.otp.isEmpty) {
      throw BadRequestException("Invalid email or OTP");
    }

    if (request.otp.length != 6) {
      throw BadRequestException("Invalid OTP");
    }

    final headers = {"Content-Type": "application/json"};
    final response = await HttpUtils.postRequest(
      "/authenticate/verify-otp",
      AuthMapper.toVerifyOtpRequest(request),
      headers: headers,
    );
    return AuthMapper.toTokenEntity(JWTToken.fromJsonString(response.body));
  }
}
