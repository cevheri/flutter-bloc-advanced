import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/connectivity_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

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
  final idempotencyKeys = <String?>[];
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
    idempotencyKeys.add(options.headers['Idempotency-Key'] as String?);
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

/// Answers each request by what it is instead of by arrival order, for requests sent concurrently.
class _RoutingHttpClientAdapter implements HttpClientAdapter {
  _RoutingHttpClientAdapter(this._route);

  final (int, String) Function(RequestOptions options) _route;
  final requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    requests.add('${options.method} ${options.path} ${options.headers['Authorization']}');
    final (statusCode, body) = _route(options);
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Replaces the [ConnectivityInterceptor] of [client], in its place in the chain, with one that reads [status], so a
/// test can take the device offline without changing the [ConnectivityService] singleton.
void _useConnectivityStatus(ApiClient client, ConnectivityStatus Function() status) {
  final interceptors = client.instance.interceptors;
  final index = interceptors.indexWhere((interceptor) => interceptor is ConnectivityInterceptor);
  expect(index, isNonNegative, reason: 'the chain must contain a ConnectivityInterceptor');
  interceptors[index] = ConnectivityInterceptor(statusProvider: status);
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

      final response = await client.post('/api/transport/retry', {'name': 'test'}, idempotent: true);

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
      // The pinned adapter's certificate callback throws CertificatePinningException during the TLS handshake,
      // HttpClient fails with it, and dio wraps it in DioExceptionType.unknown, not badCertificate.
      adapter.fail(const CertificatePinningException('api.example.test', 443));

      // The Idempotency-Key makes the POST safe to send twice, so only the error type decides against a retry.
      await expectLater(
        client.instance.post<String>(
          '/api/transport/pin-mismatch',
          data: {'name': 'test'},
          options: Options(headers: {'Idempotency-Key': 'pin-1'}),
        ),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.unknown)
              .having((e) => e.error, 'error', isA<CertificatePinningException>()),
        ),
      );
      expect(adapter.requests, hasLength(1));
    });

    // Regression: a pin mismatch on a GET was answered from the response cache as if the device were offline, so the
    // user saw the earlier data although the connection may be intercepted.
    test('fails a pin mismatch on a cached GET instead of answering it from the cache', () async {
      TestEnv.authenticate();
      adapter.reply(200, '[{"login":"admin"}]');
      final first = await client.get('/api/transport/cached');
      expect(first.data, '[{"login":"admin"}]');

      adapter.fail(const CertificatePinningException('api.example.test', 443));

      await expectLater(
        client.get('/api/transport/cached'),
        throwsA(
          isA<FetchDataException>().having((e) => e.toString(), 'message', contains('CertificatePinningException')),
        ),
      );
      expect(adapter.requests, hasLength(2));
    });

    test('records failures on ResilienceInterceptor.instance, which the dashboard reads (#60)', () async {
      adapter.reply(500);

      await expectLater(client.post('/api/transport/breaker', {'name': 'test'}), throwsA(isA<FetchDataException>()));

      expect(ResilienceInterceptor.instance.circuitBreakers['/api/transport/breaker']?.failureCount, 1);
    });
  });

  // Regression: a 503 or a timeout was retried for every HTTP method, so a POST the server had already processed
  // ran again (a second registration, a double submission). A retry is sent only when repeating the request is
  // safe: an idempotent method, or a POST or PATCH whose Idempotency-Key the retry sends again.
  group('ApiClient retry by HTTP method', () {
    late ApiClient client;
    late _FakeHttpClientAdapter adapter;

    setUp(() {
      client = ApiClient(
        appConfig: const AppConfig(
          environment: Environment.prod,
          apiBaseUrl: 'https://api.example.test',
          certificatePins: [],
          idleTimeout: null,
        ),
        secureStorage: FlutterSecureStorageAdapter(),
      );
      adapter = _FakeHttpClientAdapter()
        ..reply(503, 'unavailable')
        ..reply(200, '{"ok":true}');
      client.instance.httpClientAdapter = adapter;
      TestEnv.authenticate();
    });

    test('does not retry a POST without an Idempotency-Key and fails with the 503', () async {
      await expectLater(
        client.post('/api/retry/plain-post', {'name': 'test'}),
        throwsA(isA<FetchDataException>().having((e) => e.toString(), 'message', contains('Server error (503)'))),
      );

      expect(adapter.requests, hasLength(1), reason: 'the POST must reach the server once');
    });

    test('retries a POST that carries an Idempotency-Key and sends the same key again', () async {
      final response = await client.post('/api/retry/keyed-post', {'name': 'test'}, idempotent: true);

      expect(response.statusCode, 200);
      expect(adapter.idempotencyKeys, hasLength(2));
      expect(adapter.idempotencyKeys.first, isNotNull);
      expect(adapter.idempotencyKeys.last, adapter.idempotencyKeys.first, reason: 'the retry must reuse the key');
    });

    test('still retries a GET', () async {
      final response = await client.get('/api/retry/get');

      expect(response.statusCode, 200);
      expect(adapter.requests, hasLength(2));
    });
  });

  // Regression: the retry after a token refresh used to hang when it failed, and so did every later failing
  // request, because the retry's error queued behind the error handler that was waiting for it. Each call is
  // bounded so a regression fails the test instead of hanging the suite.
  group('ApiClient token refresh', () {
    const bound = Duration(seconds: 5);
    const rotatedTokens = '{"id_token":"NEW_JWT","refresh_token":"NEW_REFRESH"}';
    late ApiClient client;
    late _FakeHttpClientAdapter adapter;
    late int sessionExpiredCalls;

    setUp(() async {
      sessionExpiredCalls = 0;
      client = ApiClient(
        appConfig: const AppConfig(
          environment: Environment.prod,
          apiBaseUrl: 'https://api.example.test',
          certificatePins: ['test-pin'],
          idleTimeout: null,
        ),
        secureStorage: FlutterSecureStorageAdapter(),
        onSessionExpired: () => sessionExpiredCalls++,
      );
      adapter = _FakeHttpClientAdapter();
      client.instance.httpClientAdapter = adapter;
      TestEnv.authenticate();
      await FlutterSecureStorageAdapter().write(SecureStorageKeys.refreshToken.key, 'REFRESH_TOKEN');
    });

    test('fails with UnauthorizedException and expires the session once when the retry gets 401 again', () async {
      adapter
        ..reply(401)
        ..reply(200, rotatedTokens)
        ..reply(401, 'Unauthorized');

      await expectLater(client.get('/api/refresh/retry-401').timeout(bound), throwsA(isA<UnauthorizedException>()));

      expect(sessionExpiredCalls, 1);
      expect(adapter.requests.map((r) => '${r.method} ${r.path} ${r.authorization}'), [
        'GET /api/refresh/retry-401 Bearer MOCK_TOKEN',
        'POST /api/token/refresh null',
        'GET /api/refresh/retry-401 Bearer NEW_JWT',
      ], reason: 'a second 401 must not start another refresh');
    });

    test('fails with the server error when the retry gets 500, and later failures still complete', () async {
      adapter
        ..reply(401)
        ..reply(200, rotatedTokens)
        ..reply(500, 'boom');

      await expectLater(
        client.get('/api/refresh/retry-500').timeout(bound),
        throwsA(isA<FetchDataException>().having((e) => e.toString(), 'message', contains('Server error (500)'))),
      );
      expect(sessionExpiredCalls, 0);
      expect(
        ResilienceInterceptor.instance.circuitBreakers['/api/refresh/retry-500']?.failureCount,
        1,
        reason: 'one failed retry is one breaker failure',
      );

      adapter.reply(404, 'missing');
      await expectLater(
        client.get('/api/refresh/later').timeout(bound),
        throwsA(isA<FetchDataException>().having((e) => e.toString(), 'message', contains('Not found'))),
      );
    });

    test('refreshes once when several requests get 401 at the same time', () async {
      final routing = _RoutingHttpClientAdapter(
        (options) => switch ((options.method, options.headers['Authorization'])) {
          ('POST', _) => (200, rotatedTokens),
          (_, 'Bearer NEW_JWT') => (200, '{"ok":true}'),
          _ => (401, ''),
        },
      );
      client.instance.httpClientAdapter = routing;

      final responses = await Future.wait([
        for (final path in ['/api/refresh/a', '/api/refresh/b', '/api/refresh/c']) client.get(path),
      ]).timeout(bound);

      expect(responses.map((r) => r.statusCode), [200, 200, 200]);
      expect(routing.requests.where((r) => r.startsWith('POST /api/token/refresh')), hasLength(1));
      expect(routing.requests.where((r) => r.endsWith('Bearer NEW_JWT')), hasLength(3));
      expect(sessionExpiredCalls, 0);
    });
  });

  // Regression: an email in a request path, such as the login the user list fetches a user by, was printed as it
  // was by every logger on the way, also on lines that production prints: the retry and give-up lines, the line that
  // rejects a request while the circuit is open, and the HTTP error line. On web with a Sentry DSN each printed line
  // also becomes a breadcrumb.
  group('ApiClient log output', () {
    test('masks an email in the request path on every line while the server answers 503', () {
      fakeAsync((async) {
        final client = ApiClient(
          appConfig: const AppConfig(
            environment: Environment.prod,
            apiBaseUrl: 'https://api.example.test',
            certificatePins: [],
            idleTimeout: null,
          ),
          secureStorage: FlutterSecureStorageAdapter(),
        );
        final adapter = _RoutingHttpClientAdapter((_) => (503, ''));
        client.instance.httpClientAdapter = adapter;
        // The circuit breakers are shared by every client in this isolate, and this test leaves one open.
        addTearDown(ResilienceInterceptor.instance.resetAll);
        TestEnv.authenticate();
        final lines = _capturePrintedLines();
        final failures = <Object>[];

        // The GET and its three retries fail. Fetching the same user again fails once more, which opens the
        // circuit, and the third fetch is rejected while it is open. Each call gets more fake time than its retry
        // backoff can take.
        for (var call = 0; call < 3; call++) {
          client.get('/admin/users', pathParams: 'jane.doe@example.com').then<void>((_) {}, onError: failures.add);
          async.elapse(const Duration(seconds: 5));
        }

        expect(failures, [isA<FetchDataException>(), isA<CircuitBreakerOpenException>(), isA<AppException>()]);
        expect(adapter.requests, hasLength(5));
        expect(
          lines,
          containsAll(<Matcher>[
            contains('ResilienceInterceptor : Retry 1/3 for GET /admin/users/[REDACTED_EMAIL] in '),
            contains('ResilienceInterceptor : Retry 3/3 failed for GET /admin/users/[REDACTED_EMAIL] '),
            contains('Http : GET /admin/users/[REDACTED_EMAIL] -> ERROR: badResponse '),
            contains('rejecting request GET /admin/users/[REDACTED_EMAIL]'),
          ]),
        );
        expect(lines, everyElement(isNot(contains('jane.doe'))));
      });
    });
  });

  // Regression: while ConnectivityService reported the device offline, a GET failed with "No Internet connection"
  // although its response was cached. ConnectivityInterceptor rejected it without running any onError handler, so
  // CacheInterceptor never got the chance to answer it.
  group('ApiClient while the device is offline', () {
    const cached = '[{"login":"admin"}]';
    late ApiClient client;
    late _FakeHttpClientAdapter adapter;
    late ConnectivityStatus status;
    late int sessionExpiredCalls;

    setUp(() {
      status = ConnectivityStatus.online;
      sessionExpiredCalls = 0;
      client = ApiClient(
        appConfig: const AppConfig(
          environment: Environment.prod,
          apiBaseUrl: 'https://api.example.test',
          certificatePins: [],
          idleTimeout: null,
        ),
        secureStorage: FlutterSecureStorageAdapter(),
        onSessionExpired: () => sessionExpiredCalls++,
      );
      adapter = _FakeHttpClientAdapter();
      client.instance.httpClientAdapter = adapter;
      _useConnectivityStatus(client, () => status);
      TestEnv.authenticate();
    });

    test('answers a cached GET from the cache, marked stale, without sending it', () async {
      adapter.reply(200, cached);
      await client.get('/api/offline/cached');
      status = ConnectivityStatus.offline;

      final response = await client.get('/api/offline/cached');

      expect(response.data, cached);
      expect(response.headers.value('x-cache'), 'stale');
      expect(adapter.requests, hasLength(1), reason: 'only the GET sent while online may reach the network');
      expect(sessionExpiredCalls, 0);
    });

    test('answers a cacheFirst GET from the cache', () async {
      final cacheFirst = Options(extra: {'cachePolicy': CachePolicy.cacheFirst});
      adapter.reply(200, cached);
      await client.instance.get<String>('/api/offline/cache-first', options: cacheFirst);
      status = ConnectivityStatus.offline;

      final response = await client.instance.get<String>('/api/offline/cache-first', options: cacheFirst);

      expect(response.data, cached);
      expect(response.headers.value('x-cache'), 'stale');
      expect(adapter.requests, hasLength(1));
    });

    // Repositories map this message to a NetworkError, which the screens show as a connection problem.
    test('fails a GET with nothing cached with the no-connection error', () async {
      status = ConnectivityStatus.offline;

      await expectLater(
        client.get('/api/offline/uncached'),
        throwsA(isA<FetchDataException>().having((e) => e.toString(), 'message', contains('No Internet connection'))),
      );
      expect(adapter.requests, isEmpty);
      expect(sessionExpiredCalls, 0);
    });

    test('fails a POST with the no-connection error', () async {
      status = ConnectivityStatus.offline;

      await expectLater(
        client.post('/api/offline/post', {'name': 'test'}),
        throwsA(isA<FetchDataException>().having((e) => e.toString(), 'message', contains('No Internet connection'))),
      );
      expect(adapter.requests, isEmpty);
    });

    // A retry sent while the device reports offline only delays the cached answer, and every failure it records
    // brings the endpoint's circuit closer to opening, which would then reject the endpoint once the device is online.
    test('neither retries an offline GET nor counts it against the circuit breaker', () async {
      adapter.reply(200, cached);
      await client.get('/api/offline/breaker');
      status = ConnectivityStatus.offline;

      await client.get('/api/offline/breaker');

      expect(adapter.requests, hasLength(1), reason: 'no retry may be sent while the device is offline');
      expect(ResilienceInterceptor.instance.circuitBreakers['/api/offline/breaker']?.failureCount, 0);
    });

    test('records a failed offline request in the dev console and the HTTP log', () async {
      final lines = _capturePrintedLines();
      DevConsoleStore.instance.clearNetwork();
      addTearDown(DevConsoleStore.instance.clearNetwork);
      status = ConnectivityStatus.offline;

      await expectLater(client.get('/api/offline/logged'), throwsA(isA<FetchDataException>()));

      final entry = DevConsoleStore.instance.networkEntries.single;
      expect(entry.method, 'GET');
      expect(entry.url, 'https://api.example.test/api/offline/logged');
      expect(entry.isComplete, isTrue);
      expect(entry.error, startsWith('connectionError: '));
      expect(lines, contains(contains('Http : GET /api/offline/logged -> ERROR: connectionError')));
    });
  });
}

/// Collects every line the loggers print until the test ends, whichever logger prints it.
List<String> _capturePrintedLines() {
  final lines = <String>[];
  void collect(OutputEvent event) => lines.addAll(event.lines);

  Logger.addOutputListener(collect);
  addTearDown(() => Logger.removeOutputListener(collect));
  return lines;
}
