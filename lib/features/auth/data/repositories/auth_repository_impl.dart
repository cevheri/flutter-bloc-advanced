import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/mappers/auth_mapper.dart';
import 'package:flutter_bloc_advance/features/auth/data/models/jwt_token.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

class LoginRepository implements IAuthRepository {
  static final _log = AppLogger.getLogger("LoginRepository");

  LoginRepository();

  @override
  Future<Result<AuthTokenEntity>> authenticate(AuthCredentialsEntity userJWT) async {
    _log.debug("BEGIN:authenticate repository start username: {}", [userJWT.username]);
    try {
      if (userJWT.username.isEmpty || userJWT.password.isEmpty) {
        return const Failure(ValidationError("Invalid username or password"));
      }

      final request = AuthMapper.toUserJwt(userJWT);
      final response = await ApiClient.post("/authenticate", request);
      final result = JWTToken.fromJsonString(response.data!);
      _log.debug("END:authenticate successful - response.body: {}", [result.toString()]);
      final entity = AuthMapper.toTokenEntity(result);
      if (entity == null) {
        return const Failure(UnknownError("Failed to parse authentication token"));
      }
      return Success(entity);
    } on UnauthorizedException catch (e) {
      _log.error("END:authenticate auth error: {}", [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error("END:authenticate validation error: {}", [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error("END:authenticate network error: {}", [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e, st) {
      _log.error("END:authenticate error: {}", [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> logout() async {
    _log.debug("BEGIN:logout repository start");
    try {
      await AppLocalStorage().clear();
      _log.debug("END:logout successful");
      return const Success(null);
    } catch (e, st) {
      _log.error("END:logout error: {}", [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> sendOtp(SendOtpEntity request) async {
    _log.debug("BEGIN:sendOtp repository start email: {}", [request.email]);
    try {
      if (request.email.isEmpty) {
        return const Failure(ValidationError("Invalid email"));
      }
      final response = await ApiClient.post(
        "/authenticate/send-otp",
        AuthMapper.toSendOtpRequest(request),
        headers: {"Content-Type": "application/json"},
      );
      if ((response.statusCode ?? 0) >= 400) {
        return Failure(ServerError(response.data ?? ''));
      }
      _log.debug("successful response: {}", [response.data]);
      _log.debug("END:sendOtp successful");
      return const Success(null);
    } on UnauthorizedException catch (e) {
      _log.error("END:sendOtp auth error: {}", [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error("END:sendOtp validation error: {}", [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error("END:sendOtp network error: {}", [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e, st) {
      _log.error("END:sendOtp error: {}", [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }

  @override
  Future<Result<AuthTokenEntity>> verifyOtp(VerifyOtpEntity request) async {
    _log.debug("BEGIN:verifyOtp repository start email: {}", [request.email]);
    try {
      if (request.email.isEmpty || request.otp.isEmpty) {
        return const Failure(ValidationError("Invalid email or OTP"));
      }

      if (request.otp.length != 6) {
        return const Failure(ValidationError("Invalid OTP"));
      }

      final response = await ApiClient.post(
        "/authenticate/verify-otp",
        AuthMapper.toVerifyOtpRequest(request),
        headers: {"Content-Type": "application/json"},
      );
      final entity = AuthMapper.toTokenEntity(JWTToken.fromJsonString(response.data!));
      if (entity == null) {
        return const Failure(UnknownError("Failed to parse OTP token"));
      }
      return Success(entity);
    } on UnauthorizedException catch (e) {
      _log.error("END:verifyOtp auth error: {}", [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error("END:verifyOtp validation error: {}", [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error("END:verifyOtp network error: {}", [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e, st) {
      _log.error("END:verifyOtp error: {}", [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }

  static AppError _mapFetchDataException(FetchDataException e) {
    final message = e.toString().toLowerCase();
    if (message.contains('timeout')) return TimeoutError(e.toString());
    return NetworkError(e.toString());
  }
}
