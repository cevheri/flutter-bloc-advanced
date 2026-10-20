import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

final _log = AppLogger.getLogger("BusinessException");

abstract class AppException implements Exception {
  final String? _message;
  final String? _prefix;

  AppException(String? message, String? prefix) : _message = message, _prefix = prefix {
    _log.error('{}{}', [_prefix, _message]);
  }

  @override
  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends AppException {
  FetchDataException(String message) : super(message, "Error During Communication: ");
}

/// Thrown when the server presents a certificate the app does not trust,
/// such as one that matches none of the configured certificate pins. The
/// connection may be intercepted.
///
/// A repository should report it with `AppErrorCode.networkCertInvalid` so
/// the UI can show a translated message. The message of this exception names the
/// host and port and is meant for the log.
final class UntrustedCertificateException extends FetchDataException {
  UntrustedCertificateException(super.message);
}

final class BadRequestException extends AppException {
  BadRequestException([String? message]) : super(message, "Invalid Request: ");
}

final class UnauthorizedException extends AppException {
  UnauthorizedException([String? message]) : super(message, "Unauthorized: ");
}

/// Thrown when a circuit breaker is in the OPEN state, rejecting requests
/// to prevent cascading failures against an unhealthy endpoint.
class CircuitBreakerOpenException extends AppException {
  /// The endpoint key whose circuit breaker is open.
  final String endpoint;

  CircuitBreakerOpenException(this.endpoint) : super(endpoint, "Circuit Breaker Open: ");
}
