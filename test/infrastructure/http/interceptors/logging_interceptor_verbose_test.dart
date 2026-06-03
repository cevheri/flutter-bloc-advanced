import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/logging_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Behaviour of the opt-in verbose request/response body logging.
///
/// The interceptor's [LoggingInterceptor.formatRequest] /
/// [LoggingInterceptor.formatResponse] are pure string builders so the
/// redaction contract can be asserted directly without capturing console
/// output. `onRequest`/`onResponse` are thin wrappers that feed these to
/// AppLogger.
void main() {
  tearDown(() {
    // Static flag must never leak across tests.
    LoggingInterceptor.verbose = false;
  });

  group('verbose flag', () {
    test('defaults to false', () {
      expect(LoggingInterceptor.verbose, isFalse);
    });
  });

  group('formatRequest', () {
    test('concise mode omits the body entirely', () {
      LoggingInterceptor.verbose = false;
      final options = RequestOptions(
        path: '/api/login',
        method: 'POST',
        baseUrl: 'https://api.example.com',
        data: {'username': 'alice', 'password': 'sup3rsecret'},
      );

      final line = LoggingInterceptor.formatRequest(options);

      expect(line, contains('POST'));
      expect(line, contains('/api/login'));
      expect(line.contains('sup3rsecret'), isFalse);
      expect(line.contains('alice'), isFalse, reason: 'concise mode logs no body');
    });

    test('verbose mode includes the body but redacts secret keys', () {
      LoggingInterceptor.verbose = true;
      final options = RequestOptions(
        path: '/api/login',
        method: 'POST',
        data: {'username': 'alice', 'password': 'sup3rsecret'},
      );

      final line = LoggingInterceptor.formatRequest(options);

      expect(line.contains('alice'), isTrue, reason: 'non-secret fields are shown');
      expect(line.contains('sup3rsecret'), isFalse, reason: 'password value must be redacted');
    });

    test('verbose mode drops the Authorization header value', () {
      LoggingInterceptor.verbose = true;
      final options = RequestOptions(
        path: '/api/users',
        method: 'GET',
        headers: {'Authorization': 'Bearer secrettoken', 'Accept': 'application/json'},
      );

      final line = LoggingInterceptor.formatRequest(options);

      expect(line.contains('secrettoken'), isFalse);
      expect(line.contains('application/json'), isTrue);
    });

    test('verbose mode masks a JWT embedded in a raw string body', () {
      LoggingInterceptor.verbose = true;
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';
      final options = RequestOptions(path: '/api/token', method: 'POST', data: '{"refresh":"$jwt"}');

      final line = LoggingInterceptor.formatRequest(options);

      expect(line.contains(jwt), isFalse);
      expect(line.contains('[REDACTED_JWT]'), isTrue);
    });
  });

  group('formatResponse', () {
    test('concise mode reports length, not the body', () {
      LoggingInterceptor.verbose = false;
      final requestOptions = RequestOptions(path: '/api/users', method: 'GET');
      final response = Response(requestOptions: requestOptions, statusCode: 200, data: '{"secret":"abc123"}');

      final line = LoggingInterceptor.formatResponse(response);

      expect(line, contains('200'));
      expect(line.contains('abc123'), isFalse);
    });

    test('verbose mode includes the body and masks a JWT in it', () {
      LoggingInterceptor.verbose = true;
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';
      final requestOptions = RequestOptions(path: '/api/login', method: 'POST');
      final response = Response(requestOptions: requestOptions, statusCode: 200, data: '{"token":"$jwt"}');

      final line = LoggingInterceptor.formatResponse(response);

      expect(line.contains(jwt), isFalse);
      expect(line.contains('[REDACTED_JWT]'), isTrue);
    });
  });
}
