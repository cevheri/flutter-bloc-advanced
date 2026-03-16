import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

final _log = AppLogger.getLogger("BusinessException");

abstract class AppException implements Exception {
  final String? _message;
  final String? _prefix;

  AppException(String? message, String? prefix) : _message = message, _prefix = prefix {
    _log.error("$_prefix$_message");
  }

  @override
  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends AppException {
  FetchDataException(String message) : super(message, "Error During Communication: ");
}

final class BadRequestException extends AppException {
  BadRequestException([String? message]) : super(message, "Invalid Request: ");
}

final class UnauthorizedException extends AppException {
  UnauthorizedException([String? message]) : super(message, "Unauthorized: ");
}

class InvalidInputException extends AppException {
  InvalidInputException(String message) : super(message, "Invalid Input: ");
}

class ApiBusinessException extends AppException {
  ApiBusinessException(String message) : super(message, "Api Business Exception: ");
}

/// Thrown when a circuit breaker is in the OPEN state, rejecting requests
/// to prevent cascading failures against an unhealthy endpoint.
class CircuitBreakerOpenException extends AppException {
  /// The endpoint key whose circuit breaker is open.
  final String endpoint;

  CircuitBreakerOpenException(this.endpoint) : super(endpoint, "Circuit Breaker Open: ");
}
