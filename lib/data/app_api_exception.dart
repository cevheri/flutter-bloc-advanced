import 'package:flutter_bloc_advance/configuration/app_logger.dart';

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
  BadRequestException([message]) : super(message, "Invalid Request: ");
}

final class UnauthorizedException extends AppException {
  UnauthorizedException([message]) : super(message, "Unauthorized: ");
}

class InvalidInputException extends AppException {
  InvalidInputException(String message) : super(message, "Invalid Input: ");
}

class ApiBusinessException extends AppException {
  ApiBusinessException(String message) : super(message, "Api Business Exception: ");
}
