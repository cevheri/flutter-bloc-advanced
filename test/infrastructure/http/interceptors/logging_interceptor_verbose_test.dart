import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/logging_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../../../support/test_env.dart';

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

    // Regression: a String body was only run through maskJwts, and ApiClient receives every response as a String, so
    // verbose mode printed the access and refresh tokens of a sign-in response that are not JWTs.
    test('verbose mode masks the tokens of a JSON response body that are not JWTs', () {
      LoggingInterceptor.verbose = true;
      final response = Response(
        requestOptions: RequestOptions(path: '/authenticate', method: 'POST'),
        statusCode: 200,
        data: '{"id_token":"at-opaque-0a1b2c3d4e5f6a7b","refresh_token":"rt-9f8e7d6c5b4a3f2e1d0c"}',
      );

      final line = LoggingInterceptor.formatResponse(response);

      expect(line, allOf(contains('id_token'), contains('refresh_token')));
      expect(line, allOf(isNot(contains('at-opaque-0a1b2c3d4e5f6a7b')), isNot(contains('rt-9f8e7d6c5b4a3f2e1d0c'))));
    });

    test(
      'verbose mode prints the sign-in and OTP requests of main_local without their credentials or tokens',
      () async {
        LoggingInterceptor.verbose = true;
        final lines = <String>[];
        void collect(OutputEvent event) => lines.addAll(event.lines);
        Logger.addOutputListener(collect);
        addTearDown(() => Logger.removeOutputListener(collect));
        final api = TestEnv.apiClient();

        await api.post('/authenticate', {'username': 'admin', 'password': 'S3cret!pw'});
        await api.post('/authenticate/verify-otp', {'email': 'otp.user@example.com', 'otp': '493817'});

        expect(lines, anyElement(contains('Http : POST /authenticate -> 201')));
        for (final secret in ['S3cret!pw', '493817', 'MOCK_TOKEN', 'MOCK_REFRESH_TOKEN']) {
          expect(lines, everyElement(isNot(contains(secret))));
        }
      },
    );

    test('verbose mode includes the body and masks a JWT in it', () {
      LoggingInterceptor.verbose = true;
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';
      final requestOptions = RequestOptions(path: '/api/login', method: 'POST');
      // A field whose name is not a credential word, which only the JWT shape gives away.
      final response = Response(requestOptions: requestOptions, statusCode: 200, data: '{"session":"$jwt"}');

      final line = LoggingInterceptor.formatResponse(response);

      expect(line.contains(jwt), isFalse);
      expect(line.contains('[REDACTED_JWT]'), isTrue);
    });
  });
}
