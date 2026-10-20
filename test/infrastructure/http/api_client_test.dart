import 'dart:convert';
import 'dart:io' show HandshakeException;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

/// Interceptor that stubs responses before any real HTTP call.
class _StubInterceptor extends Interceptor {
  Response<String>? _successResponse;
  DioException? _dioError;

  void stubSuccess({required String data, int statusCode = 200}) {
    _successResponse = Response(requestOptions: RequestOptions(), data: data, statusCode: statusCode);
    _dioError = null;
  }

  void stubDioError(DioExceptionType type, {String? message, int? statusCode, String? data}) {
    _successResponse = null;
    final requestOptions = RequestOptions();
    _dioError = DioException(
      requestOptions: requestOptions,
      type: type,
      message: message,
      response: statusCode != null
          ? Response(requestOptions: requestOptions, statusCode: statusCode, data: data ?? '')
          : null,
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_dioError != null) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: _dioError!.type,
          message: _dioError!.message,
          error: _dioError!.error,
          response: _dioError!.response != null
              ? Response(
                  requestOptions: options,
                  statusCode: _dioError!.response!.statusCode,
                  data: _dioError!.response!.data,
                )
              : null,
        ),
      );
      return;
    }
    if (_successResponse != null) {
      handler.resolve(
        Response(requestOptions: options, data: _successResponse!.data, statusCode: _successResponse!.statusCode),
      );
      return;
    }
    handler.next(options);
  }
}

/// Records every request that reaches it and answers from a queue. Installed in the
/// `httpClientAdapter` slot of the client's Dio, where `ApiClient` puts the certificate-pinning
/// adapter, it shows which requests travel through that transport.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  final requests = <({String method, String path, String? authorization, String? body})>[];
  final _replies = <Object>[];
  bool closed = false;

  void reply(int statusCode, [String body = '']) => _replies.add((statusCode, body));

  void fail(Object error) => _replies.add(error);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = requestStream == null ? null : utf8.decode(await requestStream.expand((chunk) => chunk).toList());
    requests.add((
      method: options.method,
      path: options.path,
      authorization: options.headers['Authorization'] as String?,
      body: body,
    ));
    if (_replies.isEmpty) throw StateError('No reply queued for ${options.method} ${options.path}');
    return switch (_replies.removeAt(0)) {
      (final int statusCode, final String body) => ResponseBody.fromString(
        body,
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
      final Object error => throw error,
    };
  }

  @override
  void close({bool force = false}) => closed = true;
}

void main() {
  group('Api Exceptions', () {
    test('given FetchDataException when created then should return message', () {
      final exception = FetchDataException('Test Fetch Data Exception');
      expect(exception.toString(), equals('Error During Communication: Test Fetch Data Exception'));
    });
    test('given BadRequestException when created then should return message', () {
      final exception = BadRequestException('Test Bad Request');
      expect(exception.toString(), equals('Invalid Request: Test Bad Request'));
    });
    test('given UnauthorizedException when created then should return message', () {
      final exception = UnauthorizedException('Test access denied');
      expect(exception.toString(), equals('Unauthorized: Test access denied'));
    });
    test('given InvalidInputException when created then should return message', () {
      final exception = InvalidInputException('Test invalid data');
      expect(exception.toString(), equals('Invalid Input: Test invalid data'));
    });
    test('given ApiBusinessException when created then should return message', () {
      final exception = ApiBusinessException('Test Business Exception');
      expect(exception.toString(), equals('Api Business Exception: Test Business Exception'));
    });
  });

  group('ApiClient Tests', () {
    late _StubInterceptor stub;
    late ApiClient client;

    setUp(() {
      stub = _StubInterceptor();
      final testDio = Dio(BaseOptions(baseUrl: 'https://test.api', responseType: ResponseType.plain));
      testDio.interceptors.add(stub);
      client = ApiClient(appConfig: const AppConfig.prod(), dio: testDio);
    });

    group('HTTP Requests', () {
      test('given valid data when post request is made then should return success response', () async {
        stub.stubSuccess(data: '{"success": true}', statusCode: 200);
        final response = await client.post('/test', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given socket exception when post request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed');
        await expectLater(
          client.post('/test', {'data': 'test'}),
          throwsA(
            allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('No Internet connection'))]),
          ),
        );
      });

      test('given timeout when post request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.connectionTimeout, message: 'Timeout');
        await expectLater(
          client.post('/test', {'data': 'test'}),
          throwsA(allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('TimeoutException'))])),
        );
      });

      test('given valid data when get request is made then should return success 200', () async {
        stub.stubSuccess(data: '{"success": true}', statusCode: 200);
        final response = await client.get('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given connection error when get request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed');
        await expectLater(
          client.get('/test'),
          throwsA(
            allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('No Internet connection'))]),
          ),
        );
      });

      test('given 401 response when get request is made then should throw UnauthorizedException', () async {
        stub.stubDioError(DioExceptionType.badResponse, statusCode: 401, data: 'Unauthorized');
        await expectLater(
          client.get('/test'),
          throwsA(allOf([isA<UnauthorizedException>(), predicate((e) => e.toString().contains('Unauthorized'))])),
        );
      });

      test('given timeout when get request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.receiveTimeout, message: 'Timeout');
        await expectLater(
          client.get('/test'),
          throwsA(allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('TimeoutException'))])),
        );
      });

      test('given transform timeout when get request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.transformTimeout, message: 'Timeout');
        await expectLater(
          client.get('/test'),
          throwsA(allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('TimeoutException'))])),
        );
      });

      test('given valid data when put request is made then should return success 200', () async {
        stub.stubSuccess(data: '{"success": true}', statusCode: 200);
        final response = await client.put('/test', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given connection error when put request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed');
        await expectLater(client.put('/test', {'data': 'test'}), throwsA(isA<FetchDataException>()));
      });

      test('given timeout when put request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.sendTimeout, message: 'Timeout');
        await expectLater(
          client.put('/test', {'data': 'test'}),
          throwsA(allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('TimeoutException'))])),
        );
      });

      group('PATCH', () {
        test('given valid data when patch request is made then should return success 200', () async {
          stub.stubSuccess(data: '{"success": true}', statusCode: 200);
          final response = await client.patch('/test', {'data': 'test'});
          expect(response.statusCode, lessThan(300));
        });

        test('given connection error when patch request is made then should throw FetchDataException', () async {
          stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed');
          await expectLater(client.patch('/test', {'data': 'test'}), throwsA(isA<FetchDataException>()));
        });

        test('given timeout when patch request is made then should throw FetchDataException', () async {
          stub.stubDioError(DioExceptionType.receiveTimeout, message: 'Timeout');
          await expectLater(
            client.patch('/test', {'data': 'test'}),
            throwsA(allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('TimeoutException'))])),
          );
        });
      });

      test('given valid data when delete request is made then should return success 204', () async {
        stub.stubSuccess(data: '{"success": true}', statusCode: 204);
        final response = await client.delete('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given 401 when delete request is made then should throw UnauthorizedException', () async {
        stub.stubDioError(DioExceptionType.badResponse, statusCode: 401, data: 'Unauthorized');
        await expectLater(
          client.delete('/test'),
          throwsA(allOf([isA<UnauthorizedException>(), predicate((e) => e.toString().contains('Unauthorized'))])),
        );
      });

      test('given connection error when delete request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed');
        await expectLater(client.delete('/test'), throwsA(isA<FetchDataException>()));
      });

      test('given timeout when delete request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.receiveTimeout, message: 'Timeout');
        await expectLater(client.delete('/test'), throwsA(isA<FetchDataException>()));
      });

      test('given 400 when request is made then should throw BadRequestException', () async {
        stub.stubDioError(DioExceptionType.badResponse, statusCode: 400, data: 'Bad Request');
        await expectLater(
          client.post('/test', {'data': 'test'}),
          throwsA(allOf([isA<BadRequestException>(), predicate((e) => e.toString().contains('Bad Request'))])),
        );
      });
    });

    group('Mock Requests', () {
      late ApiClient mockClient;

      setUp(() {
        // Build a fresh test-env client so the MockInterceptor is in the chain.
        mockClient = TestEnv.apiClient();
      });

      test('given test environment when GET request is made then should return mock data', () async {
        TestEnv.authenticate();
        final response = await mockClient.get('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when GET request is made then should throw', () async {
        expect(() => mockClient.get('/test'), throwsA(isA<UnauthorizedException>()));
      });

      test('given test environment when POST request is made then should return mock data', () async {
        TestEnv.authenticate();
        final response = await mockClient.post('/test', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when POST request is made then should throw', () async {
        expect(() => mockClient.post('/test', {'data': 'test'}), throwsA(isA<UnauthorizedException>()));
      });

      test('given test environment when PUT request is made then should return mock data', () async {
        TestEnv.authenticate();
        final response = await mockClient.put('/test', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when PUT request is made then should throw', () async {
        expect(() => mockClient.put('/test', {'data': 'test'}), throwsA(isA<UnauthorizedException>()));
      });

      test('given test environment when DELETE request is made then should return 204', () async {
        TestEnv.authenticate();
        final response = await mockClient.delete('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when DELETE request is made then should throw', () async {
        expect(() => mockClient.delete('/test'), throwsA(isA<UnauthorizedException>()));
      });
    });
  });

  group('ApiClient utilities', () {
    test('decodeUTF8 should handle valid UTF-8 string', () {
      const testString = 'Test String üğişçöIİÜĞŞÇÖ';
      final decoded = ApiClient.decodeUTF8(testString);
      expect(decoded, equals(testString));
    });

    test('decodeUTF8 should return original on failure', () {
      const testString = 'Simple ASCII';
      final decoded = ApiClient.decodeUTF8(testString);
      expect(decoded, equals(testString));
    });
  });

  // Regression for #63 + #64: the snapshot is the single source of
  // truth for the interceptor chain — what's exposed here is exactly
  // what gets registered with Dio. Pin the order + names so future
  // chain edits surface as a deliberate test update.
  group('ApiClient.interceptorChainSnapshot (#63, #64)', () {
    test('is populated after the Dio instance is built', () {
      // Build a test-env client and force lazy Dio construction.
      final client = TestEnv.apiClient();
      client.instance;
      expect(client.interceptorChainSnapshot, isNotEmpty);
    });

    test('lists every interceptor in declared order (non-production includes MockInterceptor)', () {
      final client = TestEnv.apiClient();
      client.instance;
      final names = client.interceptorChainSnapshot.map((e) => e.name).toList();

      expect(names, [
        'ConnectivityInterceptor',
        'AuthInterceptor',
        'TokenRefreshInterceptor',
        'IdempotencyInterceptor',
        'ResilienceInterceptor',
        'CacheInterceptor',
        'DevConsoleInterceptor',
        'LoggingInterceptor',
        // Mock simulates the network and must sit LAST so its resolved
        // response propagates back through every onResponse handler
        // (DevConsole capture + verbose logging) like a real round-trip.
        'MockInterceptor',
      ]);
    });

    test('MockInterceptor entry is flagged active=false (dev/test fallback)', () {
      final client = TestEnv.apiClient();
      client.instance;
      final mock = client.interceptorChainSnapshot.firstWhere((e) => e.name == 'MockInterceptor');
      expect(mock.active, isFalse);
    });

    test('snapshot is returned as an unmodifiable view', () {
      final client = TestEnv.apiClient();
      client.instance;
      expect(
        () => client.interceptorChainSnapshot..add(const InterceptorChainEntry(name: 'X', detail: 'X')),
        throwsUnsupportedError,
      );
    });

    // The old static-divergence hazard (review I3) is eliminated by the
    // instance/DI model: secureStorage is a constructor dependency of the
    // single shared ApiClient, so the interceptors and the repository layer
    // can no longer use different adapters. This test pins the remaining
    // observable contract — even when built WITHOUT a secureStorage (the
    // documented `_secureStorage == null` fallback branch), the client still
    // assembles its full interceptor chain. The secureStorage → Authorization
    // header wiring itself is covered by auth_interceptor_test.dart.
    test('assembles the full interceptor chain even without an injected secureStorage', () {
      // No secureStorage passed → exercises the documented `_secureStorage == null`
      // fallback branch in _createDio. AppConfig.test() keeps baseUrl empty (valid)
      // and forces the real chain (no injected Dio).
      final client = ApiClient(appConfig: const AppConfig.test());
      client.instance; // force Dio + chain construction
      final names = client.interceptorChainSnapshot.map((e) => e.name);
      expect(names, containsAll(<String>['AuthInterceptor', 'TokenRefreshInterceptor']));
    });
  });

  // Regression: retries and the token-refresh POST used to go through fresh Dio instances on the
  // default adapter, so with certificate pinning configured they were checked against system trust
  // only. Every request the client sends must go through the adapter installed on its Dio.
  group('ApiClient transport', () {
    late ApiClient client;
    late _FakeHttpClientAdapter adapter;

    setUp(() {
      // Production chain (no MockInterceptor) with pinning configured. The fake replaces the pinned
      // adapter in its slot, so it sees every request that adapter would carry.
      client = ApiClient(
        appConfig: const AppConfig(
          environment: Environment.prod,
          apiBaseUrl: 'https://api.example.test',
          certificatePins: ['test-pin'],
          idleTimeout: null,
        ),
        secureStorage: FlutterSecureStorageAdapter(),
      );
      adapter = _FakeHttpClientAdapter();
      client.instance.httpClientAdapter = adapter;
    });

    test('sends the retry of a failed request through the client adapter', () async {
      TestEnv.authenticate();
      adapter
        ..reply(503)
        ..reply(200, '{"saved":true}');

      final response = await client.post('/api/transport/retry', {'name': 'test'});

      expect(response.statusCode, 200);
      const sent = (
        method: 'POST',
        path: '/api/transport/retry',
        authorization: 'Bearer MOCK_TOKEN',
        body: '{"name":"test"}',
      );
      expect(adapter.requests, [sent, sent]);
      expect(adapter.closed, isFalse);
    });

    test('sends the token refresh POST through the client adapter', () async {
      TestEnv.authenticate();
      await FlutterSecureStorageAdapter().write(SecureStorageKeys.refreshToken.key, 'REFRESH_TOKEN');
      adapter
        ..reply(401)
        ..reply(200, '{"id_token":"NEW_JWT","refresh_token":"NEW_REFRESH"}')
        ..reply(200, '{"ok":true}');

      final response = await client.get('/api/transport/refresh');

      expect(response.statusCode, 200);
      expect(adapter.requests, [
        (method: 'GET', path: '/api/transport/refresh', authorization: 'Bearer MOCK_TOKEN', body: null),
        (method: 'POST', path: '/api/token/refresh', authorization: null, body: '{"refresh_token":"REFRESH_TOKEN"}'),
        (method: 'GET', path: '/api/transport/refresh', authorization: 'Bearer NEW_JWT', body: null),
      ]);
      expect(adapter.closed, isFalse);
    });

    test('fails a pin mismatch as DioExceptionType.unknown and never retries it', () async {
      // The pinned adapter rejects the certificate during the TLS handshake, so HttpClient throws a
      // HandshakeException and dio wraps it in DioExceptionType.unknown, not badCertificate.
      adapter.fail(const HandshakeException('Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED)'));

      await expectLater(
        client.instance.post<String>('/api/transport/pin-mismatch', data: {'name': 'test'}),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.unknown)
              .having((e) => e.error, 'error', isA<HandshakeException>()),
        ),
      );
      expect(adapter.requests, hasLength(1));
    });

    test('records failures on ResilienceInterceptor.instance, which the dashboard reads (#60)', () async {
      adapter.reply(500);

      await expectLater(client.post('/api/transport/breaker', {'name': 'test'}), throwsA(isA<FetchDataException>()));

      expect(ResilienceInterceptor.instance.circuitBreakers['/api/transport/breaker']?.failureCount, 1);
    });
  });
}
