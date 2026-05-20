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
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

class LoginRepository implements IAuthRepository {
  static final _log = AppLogger.getLogger("LoginRepository");

  LoginRepository({ISecureStorage? secureStorage}) : _secureStorage = secureStorage ?? FlutterSecureStorageAdapter();

  final ISecureStorage _secureStorage;

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
    // Best-effort cleanup across BOTH backends. Each step is wrapped in
    // its own try/catch so that a failure to delete one secure key does
    // not skip the others — partial logout is the worst outcome since
    // any leftover token would let AuthInterceptor re-attach it on the
    // next request and silently defeat logout. Any individual failure
    // surfaces as a Failure result (with the first stack trace attached
    // for diagnostics) so callers can decide whether to retry or notify
    // the user.
    final errors = <String>[];
    StackTrace? firstStackTrace;
    try {
      await _secureStorage.delete(SecureStorageKeys.jwtToken.key);
    } catch (e, st) {
      errors.add('jwt: $e');
      firstStackTrace ??= st;
    }
    try {
      await _secureStorage.delete(SecureStorageKeys.refreshToken.key);
    } catch (e, st) {
      errors.add('refresh: $e');
      firstStackTrace ??= st;
    }
    try {
      await AppLocalStorage().clear();
    } catch (e, st) {
      errors.add('local: $e');
      firstStackTrace ??= st;
    }
    if (errors.isNotEmpty) {
      final msg = errors.join('; ');
      _log.error("END:logout partial failures: {}\n{}", [msg, firstStackTrace]);
      return Failure(UnknownError(msg), stackTrace: firstStackTrace);
    }
    _log.debug("END:logout successful");
    return const Success(null);
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
