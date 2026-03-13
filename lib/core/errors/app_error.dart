/// Typed error hierarchy for structured error handling.
///
/// Used with [Result] type instead of throwing exceptions.
sealed class AppError {
  const AppError(this.message, {this.code});
  final String message;
  final String? code;

  @override
  bool operator ==(Object other) => other is AppError && other.message == message && other.code == code;

  @override
  int get hashCode => Object.hash(message, code);

  @override
  String toString() => '$runtimeType($message${code != null ? ', code: $code' : ''})';
}

/// Network connectivity error (no internet, DNS failure).
final class NetworkError extends AppError {
  const NetworkError(super.message, {super.code});
}

/// Authentication/authorization error (401, 403, expired token).
final class AuthError extends AppError {
  const AuthError(super.message, {super.code});
}

/// Input validation error (invalid form data, bad request params).
final class ValidationError extends AppError {
  const ValidationError(super.message, {super.code});
}

/// Server-side error (500, 502, 503).
final class ServerError extends AppError {
  const ServerError(super.message, {super.code});
}

/// Resource not found (404).
final class NotFoundError extends AppError {
  const NotFoundError(super.message, {super.code});
}

/// Request timeout.
final class TimeoutError extends AppError {
  const TimeoutError(super.message, {super.code});
}

/// Unknown/unexpected error.
final class UnknownError extends AppError {
  const UnknownError(super.message, {super.code});
}
