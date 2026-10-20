import 'dart:async';
import 'dart:convert';
import 'dart:io'
    show CertificateException, InternetAddress, Platform, RawSocketOption, SecureSocket, ServerSocket, Socket;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/connectivity_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../../support/loopback_tls_server.dart';
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

/// Holds the first request until [release] completes and then answers it with [body], as a server that is slow to
/// answer. Every later request finds the server unreachable.
class _SlowServerAdapter implements HttpClientAdapter {
  _SlowServerAdapter(this.body);

  final String body;
  final received = Completer<void>();
  final release = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (received.isCompleted) {
      throw DioException.connectionError(requestOptions: options, reason: 'Connection refused');
    }
    received.complete();
    await release.future;
    return ResponseBody.fromString(
      body,
      200,
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

/// Where [_startCuttingServer] cuts a connection off.
enum _Cut {
  /// As soon as the connection is accepted: over HTTPS, before the TLS handshake.
  beforeRequest('before the request arrives'),

  /// Over HTTPS, once the client hello arrived, before the server answers it.
  duringHandshake('during the TLS handshake'),

  /// Once the request arrived, before any of the response is sent.
  afterRequest('after the request'),

  /// After the response header and the first bytes of the body.
  midBody('while the body is read');

  const _Cut(this.description);

  final String description;
}

/// Starts a server on 127.0.0.1 that answers the first connection with [body] and cuts every later one off at [cut],
/// with a RST when [reset] and a FIN otherwise. Over [tls] it presents [loopbackCertificatePem].
Future<ServerSocket> _startCuttingServer({
  required String body,
  required _Cut cut,
  required bool reset,
  required bool tls,
}) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(server.close);
  var connections = 0;
  server.listen((connection) async {
    final cutOff = ++connections > 1;
    if (cutOff && reset) _resetOnClose(connection);
    if (cutOff && cut == _Cut.beforeRequest) {
      connection.destroy();
      return;
    }
    if (cutOff && cut == _Cut.duringHandshake) {
      // Closed once the client hello is read: a socket closed with unread data ends with a RST even without
      // SO_LINGER, and a FIN sent before the client hello arrives races it, so the client sees either the end of
      // the handshake or a reset.
      connection.listen((_) => connection.destroy());
      return;
    }
    final socket = tls ? await SecureSocket.secureServer(connection, loopbackServerContext()) : connection;
    final request = <int>[];
    var answered = false;
    socket.listen((data) async {
      request.addAll(data);
      if (answered || !latin1.decode(request).contains('\r\n\r\n')) return;
      answered = true;
      if (cutOff && cut == _Cut.afterRequest) {
        socket.destroy();
        return;
      }
      final bytes = utf8.encode(body);
      final cutMidBody = cutOff && cut == _Cut.midBody;
      socket
        ..add(
          latin1.encode(
            'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: ${bytes.length}\r\n'
            'Connection: close\r\n\r\n',
          ),
        )
        ..add(cutMidBody ? bytes.sublist(0, 5) : bytes);
      await socket.flush();
      if (cutMidBody && reset) {
        socket.destroy();
        return;
      }
      await socket.close();
    });
  });
  return server;
}

/// Makes [socket] end with a RST instead of a FIN when it is closed: SO_LINGER on, with a timeout of zero.
void _resetOnClose(Socket socket) {
  // SO_LINGER is 13 on Linux and 0x80 on macOS; struct linger is two 32-bit ints on both.
  final soLinger = Platform.isMacOS ? 0x80 : 13;
  socket.setRawOption(
    RawSocketOption(RawSocketOption.levelSocket, soLinger, Uint8List.fromList([1, 0, 0, 0, 0, 0, 0, 0])),
  );
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
        final response = await mockClient.get('/account');
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when GET request is made then should throw', () async {
        expect(() => mockClient.get('/test'), throwsA(isA<UnauthorizedException>()));
      });

      test('given test environment when POST request is made then should return mock data', () async {
        TestEnv.authenticate();
        final response = await mockClient.post('/account', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when POST request is made then should throw', () async {
        expect(() => mockClient.post('/test', {'data': 'test'}), throwsA(isA<UnauthorizedException>()));
      });

      test('given test environment when PUT request is made then should return mock data', () async {
        TestEnv.authenticate();
        final response = await mockClient.put('/admin/users', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when PUT request is made then should throw', () async {
        expect(() => mockClient.put('/test', {'data': 'test'}), throwsA(isA<UnauthorizedException>()));
      });

      // Regression: a request without a mock file was answered with "OK", so the demo reported success for a request
      // it could not answer.
      test('given test environment when no mock file exists then should fail naming the missing file', () async {
        TestEnv.authenticate();
        await expectLater(
          mockClient.post('/test', {'data': 'test'}),
          throwsA(
            isA<FetchDataException>().having(
              (e) => e.toString(),
              'message',
              allOf(contains('Server error (501)'), contains('assets/mock/POST_test.json')),
            ),
          ),
        );
      });

      test('given test environment when DELETE request is made then should return 204', () async {
        TestEnv.authenticate();
        final response = await mockClient.delete('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when DELETE request is made then should throw', () async {
        expect(() => mockClient.delete('/test'), throwsA(isA<UnauthorizedException>()));
      });

      // Regression: the token refresh went through a Dio without MockInterceptor, so in mock mode it went to the
      // transport instead of the mock, failed, and ended the session.
      test('given test environment when a 401 is refreshed then the mock answers the refresh', () async {
        await FlutterSecureStorageAdapter().write(SecureStorageKeys.refreshToken.key, 'MOCK_REFRESH_TOKEN');
        final adapter = _FakeHttpClientAdapter();
        mockClient.instance.httpClientAdapter = adapter;

        final response = await mockClient.get('/account');

        expect(response.statusCode, 200);
        expect(
          adapter.requests,
          isEmpty,
          reason: 'in mock mode no request may reach the network, the refresh included',
        );
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

    // Regression: a pin mismatch reached the repositories as a plain FetchDataException, so a screen showed its text,
    // host and port included, instead of a message the user can act on. The host and port stay in the log.
    test('fails a pin mismatch with UntrustedCertificateException and logs the host and port', () async {
      final errors = <String>[];
      void recordError(OutputEvent event) {
        if (event.level == Level.error) errors.addAll(event.lines);
      }

      Logger.addOutputListener(recordError);
      addTearDown(() => Logger.removeOutputListener(recordError));
      adapter.fail(const CertificatePinningException('api.example.test', 443));

      await expectLater(client.get('/api/transport/untrusted'), throwsA(isA<UntrustedCertificateException>()));
      expect(errors, contains(contains('api.example.test:443')));
    });

    // dio reports a certificate that IOHttpClientAdapter.validateCertificate rejects as badCertificate, and dart:io
    // may fail the handshake with a CertificateException; both used to reach the repositories as a plain
    // FetchDataException.
    test('fails a certificate dio rejects with UntrustedCertificateException', () async {
      adapter.fail(
        DioException.badCertificate(
          requestOptions: RequestOptions(baseUrl: 'https://api.example.test', path: '/api/transport/rejected'),
        ),
      );

      await expectLater(client.get('/api/transport/rejected'), throwsA(isA<UntrustedCertificateException>()));
    });

    test('fails a dart:io CertificateException with UntrustedCertificateException', () async {
      adapter.fail(const CertificateException('certificate rejected'));

      await expectLater(client.get('/api/transport/certificate'), throwsA(isA<UntrustedCertificateException>()));
    });

    test('records failures on ResilienceInterceptor.instance, which the dashboard reads (#60)', () async {
      adapter.reply(500);

      await expectLater(client.post('/api/transport/breaker', {'name': 'test'}), throwsA(isA<FetchDataException>()));

      expect(ResilienceInterceptor.instance.circuitBreakers['/api/transport/breaker']?.failureCount, 1);
    });
  });

  // Regression: CacheInterceptor took every unknown error without a response for a lost connection, so a TLS handshake
  // the device does not trust (an expired or self-signed certificate, a wrong device clock, an intercepting proxy or a
  // captive portal) was answered with the cached response, marked stale, as if the device were offline.
  group('ApiClient when the device does not trust the server certificate', () {
    const cached = '[{"login":"admin"}]';
    late int port;
    late ApiClient client;

    setUp(() async {
      port = (await startLoopbackTlsServer(body: cached)).port;
      // Production chain on system trust, without pins.
      client = ApiClient(
        appConfig: AppConfig(
          environment: Environment.prod,
          apiBaseUrl: 'https://127.0.0.1:$port',
          certificatePins: const [],
          idleTimeout: null,
        ),
        secureStorage: FlutterSecureStorageAdapter(),
      );
      TestEnv.authenticate();
    });

    test('fails a cached GET instead of answering it from the cache', () async {
      await withRealSockets(() async {
        final systemTrust = client.instance.httpClientAdapter;
        client.instance.httpClientAdapter = loopbackTrustingAdapter();
        final first = await client.get('/api/tls/cached');
        expect(first.data, cached);

        // The device stops trusting the certificate, as when the server certificate expires or a proxy presents its
        // own.
        client.instance.httpClientAdapter = systemTrust;

        await expectLater(
          client.get('/api/tls/cached'),
          throwsA(isA<FetchDataException>().having((e) => e.toString(), 'message', contains('HandshakeException'))),
        );
      });
    });

    // Regression: only a pin mismatch became an UntrustedCertificateException. Any other TLS failure reached the
    // repositories as a plain FetchDataException, so the screens showed its text or a generic error instead of the
    // insecure-connection message.
    test('fails with UntrustedCertificateException and logs the TLS error with the host and port', () async {
      final errors = <String>[];
      void recordError(OutputEvent event) {
        if (event.level == Level.error) errors.addAll(event.lines);
      }

      Logger.addOutputListener(recordError);
      addTearDown(() => Logger.removeOutputListener(recordError));

      await withRealSockets(() async {
        await expectLater(client.get('/api/tls/untrusted'), throwsA(isA<UntrustedCertificateException>()));
      });
      final log = errors.join('\n');
      expect(log, contains('127.0.0.1:$port'));
      expect(log, contains('CERTIFICATE_VERIFY_FAILED'));
    });

    // Regression: each TLS failure counted against the endpoint's circuit breaker, so from the sixth request on the
    // user saw "Circuit Breaker Open" instead of the insecure-connection message.
    test('keeps failing with UntrustedCertificateException instead of opening the circuit', () async {
      addTearDown(ResilienceInterceptor.instance.resetAll);

      await withRealSockets(() async {
        for (var request = 1; request <= 6; request++) {
          await expectLater(
            client.get('/api/tls/repeated'),
            throwsA(isA<UntrustedCertificateException>()),
            reason: 'request $request',
          );
        }
      });
      expect(ResilienceInterceptor.instance.circuitBreakers['/api/tls/repeated']?.failureCount, 0);
    });
  });

  // A connection closed or reset before the whole response arrived reaches the client in a shape that depends on
  // where it ends: a connection error, or an unknown error whose error is a dart:io HttpException, OSError or
  // SocketException. Only real sockets give these shapes, so a loopback server cuts the connections here.
  group('ApiClient when the server cuts the connection off', () {
    const cached = '[{"login":"admin"}]';

    tearDown(ResilienceInterceptor.instance.resetAll);

    /// The production chain, without pins, to a server that answers the first connection and cuts every later one
    /// off. Over HTTPS the client trusts the server's certificate, so only the cut can fail the handshake.
    Future<ApiClient> clientOfCuttingServer({required bool tls, required _Cut cut, required bool reset}) async {
      final server = await _startCuttingServer(body: cached, cut: cut, reset: reset, tls: tls);
      final client = ApiClient(
        appConfig: AppConfig(
          environment: Environment.prod,
          apiBaseUrl: '${tls ? 'https' : 'http'}://127.0.0.1:${server.port}',
          certificatePins: const [],
          idleTimeout: null,
        ),
        secureStorage: FlutterSecureStorageAdapter(),
      );
      if (tls) client.instance.httpClientAdapter = loopbackTrustingAdapter();
      TestEnv.authenticate();
      return client;
    }

    for (final tls in [false, true]) {
      for (final cut in _Cut.values) {
        for (final reset in [false, true]) {
          // Only HTTPS has a handshake to cut, and a FIN during it is a TLS failure, tested below.
          if (cut == _Cut.duringHandshake && (!tls || !reset)) continue;
          // Over HTTPS a FIN as soon as the connection is accepted races the client hello, see _startCuttingServer.
          if (cut == _Cut.beforeRequest && tls && !reset) continue;
          // Guards the answers the cache gave before TLS failures were kept from it: the GET could not reach the
          // server, and the connection never got to a TLS handshake, was reset during it, or had passed it.
          final connection = '${tls ? 'HTTPS' : 'HTTP'} connection is ${reset ? 'reset' : 'closed'} ${cut.description}';
          test('answers a cached GET from the cache when an $connection', () async {
            final client = await clientOfCuttingServer(tls: tls, cut: cut, reset: reset);

            await withRealSockets(() async {
              final first = await client.get('/api/cut/users');
              expect(first.headers.value('x-cache'), isNull);

              final second = await client.get('/api/cut/users');

              expect(second.data, cached);
              expect(second.headers.value('x-cache'), 'stale');
            });
          }, skip: reset && !(Platform.isLinux || Platform.isMacOS) ? 'Needs the SO_LINGER of Linux or macOS' : false);
        }
      }
    }

    // Regression: a TLS handshake that was closed before it completed was answered from the cache as a lost
    // connection, and once it no longer was, it reached the screens as a plain FetchDataException. A dropped network
    // can close a handshake this way, but so can anything between the device and the server, so it fails closed like
    // any other TLS failure, with the insecure-connection error.
    test('fails a cached GET whose TLS handshake the server ends with UntrustedCertificateException', () async {
      final client = await clientOfCuttingServer(tls: true, cut: _Cut.duringHandshake, reset: false);

      await withRealSockets(() async {
        await client.get('/api/cut/users');

        await expectLater(
          client.get('/api/cut/users'),
          throwsA(
            isA<UntrustedCertificateException>().having(
              (e) => '$e',
              'message',
              contains('Connection terminated during handshake'),
            ),
          ),
        );
      });
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

    // Regression: a refresh request that failed in transport, such as on a certificate pin mismatch, was logged as
    // "Token refresh request failed: null", because a DioException that only wraps the transport error has no message.
    // The refresh request skips the client's interceptors, so this line is the only record of why the session ended.
    test('logs the type and the cause when the refresh request fails in transport', () async {
      adapter
        ..reply(401)
        ..fail(const CertificatePinningException('api.example.test', 443));
      final lines = _capturePrintedLines();

      await expectLater(client.get('/api/refresh/pin-mismatch').timeout(bound), throwsA(isA<UnauthorizedException>()));

      expect(sessionExpiredCalls, 1);
      expect(
        lines,
        anyElement(
          endsWith(
            'TokenRefreshInterceptor : Token refresh request failed (type: unknown, message: null, error: '
            'CertificatePinningException: the certificate of api.example.test:443 matches no configured pin)',
          ),
        ),
      );
    });

    // Regression: when the retry that follows a successful refresh failed in transport, the line read
    // "Retry after refresh failed (Dio): null", for the same reason.
    test('logs the type and the cause when the retry after a refresh fails in transport', () async {
      adapter
        ..reply(401)
        ..reply(200, rotatedTokens)
        ..fail(const CertificatePinningException('api.example.test', 443));
      final lines = _capturePrintedLines();

      await expectLater(
        client.get('/api/refresh/retry-pin-mismatch').timeout(bound),
        throwsA(isA<UntrustedCertificateException>()),
      );

      expect(sessionExpiredCalls, 0);
      expect(
        lines,
        anyElement(
          endsWith(
            'TokenRefreshInterceptor : Retry after refresh failed (type: unknown, message: null, error: '
            'CertificatePinningException: the certificate of api.example.test:443 matches no configured pin)',
          ),
        ),
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

  // Regression: ApiClient put the raw body of an error response into the exception it threw, and an AppException logs
  // its text at error level when it is created, which every build of main_prod prints. A validation error can repeat
  // what the request sent, so the password of a sign-in or a change and the code of an OTP check reached the console,
  // the repository and BLoC error lines that log the exception again, and on web with a Sentry DSN the breadcrumbs.
  group('ApiClient error responses that repeat a credential', () {
    late ApiClient client;
    late _FakeHttpClientAdapter adapter;

    setUp(() {
      AppLogger.configure(isProduction: true);
      client = ApiClient(
        appConfig: const AppConfig(
          environment: Environment.prod,
          apiBaseUrl: 'https://api.example.test',
          certificatePins: [],
          idleTimeout: null,
        ),
        secureStorage: FlutterSecureStorageAdapter(),
      );
      adapter = _FakeHttpClientAdapter();
      client.instance.httpClientAdapter = adapter;
      TestEnv.authenticate();
    });

    tearDown(() => AppLogger.configure(isProduction: false));

    /// The text of the exception that [request] fails with, which the repositories and BLoCs log again.
    Future<String> failureText(Future<Object?> request) async {
      try {
        await request;
      } on AppException catch (e) {
        return e.toString();
      }
      fail('the request did not fail');
    }

    test('keeps the passwords out of a Spring validation error that repeats the rejected value', () async {
      adapter.reply(
        400,
        jsonEncode({
          'status': 400,
          'errors': [
            {'field': 'newPassword', 'rejectedValue': 'NewPass#2', 'defaultMessage': 'size must be between 8 and 100'},
          ],
        }),
      );
      final lines = _capturePrintedLines();

      final text = await failureText(
        client.post('/account/change-password', {'currentPassword': 'OldPass#1', 'newPassword': 'NewPass#2'}),
      );

      expect([text, ...lines], everyElement(allOf(isNot(contains('NewPass#2')), isNot(contains('OldPass#1')))));
      expect(text, allOf(startsWith('Invalid Request: '), contains('size must be between 8 and 100')));
      expect(lines, anyElement(contains('BusinessException : Invalid Request: ')));
    });

    test('keeps the code out of an OTP error whose detail names it', () async {
      adapter.reply(401, jsonEncode({'status': 401, 'detail': 'OTP 493817 expired for otp.user@example.com'}));
      final lines = _capturePrintedLines();

      final text = await failureText(
        client.post('/authenticate/verify-otp', {'email': 'otp.user@example.com', 'otp': '493817'}),
      );

      expect([text, ...lines], everyElement(isNot(contains('493817'))));
      expect(text, allOf(startsWith('Unauthorized: '), contains('expired for')));
    });

    test('keeps the password out of a Pydantic validation error that repeats the input', () async {
      adapter.reply(
        422,
        jsonEncode({
          'detail': [
            {
              'type': 'string_too_short',
              'loc': ['body', 'password'],
              'msg': 'String should have at least 12 characters',
              'input': 'S3cret!pw',
            },
          ],
        }),
      );
      final lines = _capturePrintedLines();

      final text = await failureText(client.post('/authenticate', {'username': 'admin', 'password': 'S3cret!pw'}));

      expect([text, ...lines], everyElement(isNot(contains('S3cret!pw'))));
      expect(text, allOf(contains('HTTP 422: '), contains('at least 12 characters')));
    });

    test('keeps the password out of a plain text error that repeats it', () async {
      adapter.reply(400, 'Password S3cret!pw is too weak');
      final lines = _capturePrintedLines();

      final text = await failureText(client.post('/authenticate', {'username': 'admin', 'password': 'S3cret!pw'}));

      expect([text, ...lines], everyElement(isNot(contains('S3cret!pw'))));
      expect(text, allOf(startsWith('Invalid Request: Password '), endsWith(' is too weak')));
    });

    // Guards against the scrub losing the body: an error without a credential reaches the log as the server sent it.
    test('keeps an error body without a credential as the server sent it', () async {
      const body = '{"status": 400, "title": "Bad Request", "detail": "login already used", "path": "/api/register"}';
      adapter.reply(400, body);

      final text = await failureText(client.post('/register', {'login': 'admin', 'email': 'admin@example.com'}));

      expect(text, 'Invalid Request: $body');
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

    // Regression: the entry is fresh, so online CacheInterceptor answers it as a hit before the network. Offline,
    // ConnectivityInterceptor rejects the GET before CacheInterceptor sees it, and the answer was marked stale.
    test('answers a cacheFirst GET with a fresh entry from the cache as a hit', () async {
      final cacheFirst = Options(extra: {'cachePolicy': CachePolicy.cacheFirst});
      adapter.reply(200, cached);
      await client.instance.get<String>('/api/offline/cache-first', options: cacheFirst);
      status = ConnectivityStatus.offline;

      final response = await client.instance.get<String>('/api/offline/cache-first', options: cacheFirst);

      expect(response.data, cached);
      expect(response.headers.value('x-cache'), 'hit');
      expect(adapter.requests, hasLength(1));
    });

    // Regression: a cacheOnly GET never reaches the network, but ConnectivityInterceptor rejected it before
    // CacheInterceptor could answer it, so it failed with the no-connection error although its response was cached.
    test('answers a cacheOnly GET from the cache', () async {
      adapter.reply(200, cached);
      await client.get('/api/offline/cache-only');
      status = ConnectivityStatus.offline;

      final response = await client.instance.get<String>(
        '/api/offline/cache-only',
        options: Options(extra: {'cachePolicy': CachePolicy.cacheOnly}),
      );

      expect(response.data, cached);
      expect(response.headers.value('x-cache'), 'hit');
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

  group('ApiClient when a GET cannot reach the server', () {
    const cached = '[{"login":"admin"}]';

    setUp(() {
      DevConsoleStore.instance.clearNetwork();
      addTearDown(DevConsoleStore.instance.clearNetwork);
    });
    tearDown(ResilienceInterceptor.instance.resetAll);

    // Regression: CacheInterceptor answered the failed GET before DevConsoleInterceptor's onError ran, which ends the
    // error chain, so the entry the dev console added for the request stayed in flight for good.
    test('completes the dev console entry of a GET the cache answers', () async {
      // The server answers the first GET and closes the connection of the second while its body is read.
      final server = await _startCuttingServer(body: cached, cut: _Cut.midBody, reset: false, tls: false);
      final client = ApiClient(
        appConfig: AppConfig(
          environment: Environment.prod,
          apiBaseUrl: 'http://127.0.0.1:${server.port}',
          certificatePins: const [],
          idleTimeout: null,
        ),
        secureStorage: FlutterSecureStorageAdapter(),
      );
      TestEnv.authenticate();

      final response = await withRealSockets(() async {
        await client.get('/api/unreachable/cached');
        return client.get('/api/unreachable/cached');
      });

      expect(response.data, cached);
      expect(response.headers.value('x-cache'), 'stale');
      final entry = DevConsoleStore.instance.networkEntries.first;
      expect(entry.url, 'http://127.0.0.1:${server.port}/api/unreachable/cached');
      expect(entry.isComplete, isTrue);
      expect(entry.statusCode, 200);
      expect(entry.responseHeaders, containsPair('x-cache', 'stale'));
      expect(entry.responseBody, cached);
      expect(entry.error, startsWith('unknown: HttpException: Connection closed while receiving data'));
    });
  });

  // ResilienceInterceptor rejects every request to an endpoint whose circuit is open, before it is sent.
  group('ApiClient while the circuit of an endpoint is open', () {
    const cached = '[{"login":"admin"}]';
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
      adapter = _FakeHttpClientAdapter();
      client.instance.httpClientAdapter = adapter;
      TestEnv.authenticate();
      // The circuit breakers are shared by every client in this isolate.
      addTearDown(ResilienceInterceptor.instance.resetAll);
    });

    /// Caches the response of a GET to [path], then fails five more until the circuit of [path] opens.
    Future<void> cacheThenOpenCircuit(String path) async {
      adapter.reply(200, cached);
      await client.get(path);
      for (var failure = 0; failure < 5; failure++) {
        adapter.reply(500, 'boom');
        await expectLater(client.get(path), throwsA(isA<FetchDataException>()));
      }
      expect(ResilienceInterceptor.instance.circuitBreakers[path]?.state, CircuitBreakerState.open);
    }

    // Regression: a cacheOnly GET never reaches the network, but the open circuit rejected it before
    // CacheInterceptor could answer it.
    test('answers a cacheOnly GET from the cache', () async {
      await cacheThenOpenCircuit('/api/circuit/cache-only');

      final response = await client.instance.get<String>(
        '/api/circuit/cache-only',
        options: Options(extra: {'cachePolicy': CachePolicy.cacheOnly}),
      );

      expect(response.data, cached);
      expect(response.headers.value('x-cache'), 'hit');
      expect(adapter.requests, hasLength(6));
    });
  });

  group('ApiClient with CachePolicy.cacheOnly', () {
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
      adapter = _FakeHttpClientAdapter();
      client.instance.httpClientAdapter = adapter;
      TestEnv.authenticate();
      DevConsoleStore.instance.clearNetwork();
      addTearDown(DevConsoleStore.instance.clearNetwork);
    });

    // Regression: CacheInterceptor rejected a cacheOnly GET with nothing cached without running any onError handler,
    // so neither the dev console nor the HTTP log recorded the failure.
    test('records a GET with nothing cached in the dev console and the HTTP log, not as an endpoint failure', () async {
      final lines = _capturePrintedLines();

      await expectLater(
        client.instance.get<String>(
          '/api/cache-only/missing',
          options: Options(extra: {'cachePolicy': CachePolicy.cacheOnly}),
        ),
        throwsA(isA<DioException>().having((e) => e.message, 'message', 'No cached data available')),
      );

      final entry = DevConsoleStore.instance.networkEntries.single;
      expect(entry.url, 'https://api.example.test/api/cache-only/missing');
      expect(entry.isComplete, isTrue);
      expect(entry.error, 'unknown: No cached data available');
      expect(
        lines,
        contains(contains('Http : GET /api/cache-only/missing -> ERROR: unknown No cached data available')),
      );
      expect(adapter.requests, isEmpty);
      expect(ResilienceInterceptor.instance.circuitBreakers['/api/cache-only/missing']?.failureCount ?? 0, 0);
    });
  });

  // Regression: a GET still on its way when the user logged out stored its response after the logout had cleared the
  // cache. The next user's GET that could not reach the server was then answered with the previous user's data.
  group('ApiClient when the session ends while a GET is on its way', () {
    tearDown(ResilienceInterceptor.instance.resetAll);

    test("does not cache the response, so it cannot answer the next user's GET", () async {
      const previousUsersData = '[{"login":"user-a","email":"a@example.test"}]';
      final server = _SlowServerAdapter(previousUsersData);
      final client = ApiClient(
        appConfig: const AppConfig(
          environment: Environment.prod,
          apiBaseUrl: 'https://api.example.test',
          certificatePins: [],
          idleTimeout: null,
        ),
        secureStorage: FlutterSecureStorageAdapter(),
      );
      client.instance.httpClientAdapter = server;
      TestEnv.authenticate();

      final slowGet = client.get('/api/admin/users');
      await server.received.future;
      // The wipe that a logout and the end of the session run.
      final cleared = await AuthSessionRepository(secureStorage: FlutterSecureStorageAdapter()).clear();
      expect(cleared, isA<Success<void>>());
      server.release.complete();
      await slowGet;
      expect(await SharedPrefsCacheStorage().count(), 0);

      // The next user signs in, and the server cannot be reached.
      TestEnv.authenticate();
      await expectLater(
        client.get('/api/admin/users'),
        throwsA(isA<FetchDataException>().having((e) => '$e', 'message', contains('No Internet connection'))),
      );
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
