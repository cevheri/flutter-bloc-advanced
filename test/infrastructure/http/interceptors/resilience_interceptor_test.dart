import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/connectivity_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResilienceInterceptor', () {
    group('constructor defaults', () {
      test('should have default maxRetries of 3', () {
        final interceptor = ResilienceInterceptor();
        expect(interceptor.maxRetries, 3);
      });

      test('should have default baseDelay of 200ms', () {
        final interceptor = ResilienceInterceptor();
        expect(interceptor.baseDelay, const Duration(milliseconds: 200));
      });

      test('should have default maxJitter of 100ms', () {
        final interceptor = ResilienceInterceptor();
        expect(interceptor.maxJitter, const Duration(milliseconds: 100));
      });

      test('should have default failureThreshold of 5', () {
        final interceptor = ResilienceInterceptor();
        expect(interceptor.failureThreshold, 5);
      });

      test('should have default cooldownDuration of 30 seconds', () {
        final interceptor = ResilienceInterceptor();
        expect(interceptor.cooldownDuration, const Duration(seconds: 30));
      });
    });

    group('onRequest — circuit breaker gating', () {
      test('should pass request through when circuit is closed', () async {
        final interceptor = ResilienceInterceptor();
        final options = RequestOptions(path: '/api/users');
        final result = await _captureOnRequest(interceptor, options);

        expect(result.passed, isTrue);
        expect(result.rejected, isFalse);
      });

      test('should reject request when circuit is open', () async {
        final interceptor = ResilienceInterceptor(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));
        final options = RequestOptions(path: '/api/users');

        // Trip the circuit breaker via onError
        for (int i = 0; i < 2; i++) {
          final err = DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 502),
          );
          _fireOnError(interceptor, err);
        }

        // Now the circuit should be open, and onRequest should reject
        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));

        expect(result.rejected, isTrue);
        expect(result.rejectError!.error, isA<CircuitBreakerOpenException>());
      });
    });

    group('onResponse — circuit breaker success recording', () {
      test('should pass response through and record success', () async {
        final interceptor = ResilienceInterceptor(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));
        final options = RequestOptions(path: '/api/users');

        // Record one failure first
        final err = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 502),
        );
        _fireOnError(interceptor, err);

        // Record a success via onResponse
        final response = Response(requestOptions: options, statusCode: 200, data: 'ok');
        final result = await _captureOnResponse(interceptor, response);

        expect(result.passed, isTrue);

        // Verify circuit is still closed (success reset it)
        final requestResult = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(requestResult.passed, isTrue);
      });
    });

    group('onError — retryable vs non-retryable errors', () {
      test('should pass through 400 Bad Request without tripping circuit breaker', () async {
        final interceptor = ResilienceInterceptor(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));
        final options = RequestOptions(path: '/api/users');

        for (int i = 0; i < 5; i++) {
          final err = DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 400),
          );
          _fireOnError(interceptor, err);
        }

        // Circuit should still be closed because 4xx errors don't trip it
        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(result.passed, isTrue);
      });

      test('should pass through 401 Unauthorized without tripping circuit breaker', () async {
        final interceptor = ResilienceInterceptor(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));
        final options = RequestOptions(path: '/api/users');

        for (int i = 0; i < 5; i++) {
          final err = DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 401),
          );
          _fireOnError(interceptor, err);
        }

        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(result.passed, isTrue);
      });

      test('should pass through 404 Not Found without tripping circuit breaker', () async {
        final interceptor = ResilienceInterceptor(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));
        final options = RequestOptions(path: '/api/users');

        for (int i = 0; i < 5; i++) {
          final err = DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 404),
          );
          _fireOnError(interceptor, err);
        }

        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(result.passed, isTrue);
      });

      test('should record failure for 502 Bad Gateway (retryable)', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 2,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );
        final options = RequestOptions(path: '/api/users');

        for (int i = 0; i < 2; i++) {
          final err = DioException(
            requestOptions: RequestOptions(path: '/api/users'),
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 502),
          );
          _fireOnError(interceptor, err);
        }

        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(result.rejected, isTrue);
      });

      test('should record failure for 503 Service Unavailable (retryable)', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 2,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );
        final options = RequestOptions(path: '/api/users');

        for (int i = 0; i < 2; i++) {
          final err = DioException(
            requestOptions: RequestOptions(path: '/api/users'),
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 503),
          );
          _fireOnError(interceptor, err);
        }

        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(result.rejected, isTrue);
      });

      test('should record failure for connection timeout (retryable)', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 2,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        for (int i = 0; i < 2; i++) {
          final err = DioException(
            requestOptions: RequestOptions(path: '/api/users'),
            type: DioExceptionType.connectionTimeout,
          );
          _fireOnError(interceptor, err);
        }

        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(result.rejected, isTrue);
      });

      test('should record failure for connection error (retryable)', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 2,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        for (int i = 0; i < 2; i++) {
          final err = DioException(
            requestOptions: RequestOptions(path: '/api/users'),
            type: DioExceptionType.connectionError,
          );
          _fireOnError(interceptor, err);
        }

        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(result.rejected, isTrue);
      });

      test('should pass through CircuitBreakerOpenException without further processing', () async {
        final interceptor = ResilienceInterceptor();
        final options = RequestOptions(path: '/api/users');
        final cbException = CircuitBreakerOpenException('/api/users');
        final err = DioException(requestOptions: options, type: DioExceptionType.unknown, error: cbException);

        final result = _captureOnErrorSync(interceptor, err);
        expect(result.passed, isTrue);
      });

      test('should not retry cancelled requests', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 10,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );
        final options = RequestOptions(path: '/api/users');
        final err = DioException(requestOptions: options, type: DioExceptionType.cancel);

        final result = _captureOnErrorSync(interceptor, err);
        // cancel is non-retryable and non-client-error, so it records failure
        expect(result.passed, isTrue);
      });

      test('should not retry bad certificate errors', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 10,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );
        final options = RequestOptions(path: '/api/users');
        final err = DioException(requestOptions: options, type: DioExceptionType.badCertificate);

        final result = _captureOnErrorSync(interceptor, err);
        expect(result.passed, isTrue);
      });

      test('should not retry transform timeout errors', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 10,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 3,
        );
        final options = RequestOptions(path: '/api/users');
        final err = DioException(requestOptions: options, type: DioExceptionType.transformTimeout);

        // Non-retryable errors pass through synchronously. A retryable one is
        // rejected here instead, because this instance was not made by forDio.
        final result = _captureOnErrorSync(interceptor, err);
        expect(result.passed, isTrue);
      });

      test('should not retry a connection the server closed after the request was sent', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 10,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 3,
        );
        // GET, because a POST without an Idempotency-Key is never retried anyway.
        final options = RequestOptions(path: '/api/users', method: 'GET');
        // Built the way dio 5.10+ reports it (io_adapter.dart); dio 5.9 reported it as unknown.
        const closed = HttpException('Connection closed before full header was received');
        final err = DioException.connectionError(requestOptions: options, reason: closed.message, error: closed);

        final result = _captureOnErrorSync(interceptor, err);
        expect(result.passed, isTrue);
      });

      test('should still retry other connection errors', () {
        fakeAsync((async) {
          final interceptor = ResilienceInterceptor(
            failureThreshold: 10,
            cooldownDuration: const Duration(hours: 1),
            maxRetries: 3,
          ).forDio(Dio());
          final options = RequestOptions(path: '/api/users', method: 'GET');
          const refused = SocketException('Connection refused');
          final err = DioException.connectionError(requestOptions: options, reason: refused.message, error: refused);

          // The retry waits for its backoff delay, which never elapses in fake time.
          final result = _captureOnErrorSync(interceptor, err);
          expect(result.passed, isFalse);
        });
      });

      // ConnectivityInterceptor rejects a request while the device is offline, before it is sent. A retry would only
      // delay the cached answer, and a recorded failure would count against an endpoint that never failed.
      test('should pass an offline rejection through without retrying it or recording a failure', () {
        fakeAsync((async) {
          final shared = ResilienceInterceptor(
            failureThreshold: 1,
            cooldownDuration: const Duration(hours: 1),
            maxRetries: 3,
          );
          final err = DioException(
            requestOptions: RequestOptions(path: '/api/users', method: 'GET'),
            type: DioExceptionType.connectionError,
            error: const ConnectivityException(),
          );

          // Passed on at once instead of waiting for a retry's backoff delay.
          final result = _captureOnErrorSync(shared.forDio(Dio()), err);
          expect(result.passed, isTrue);

          final next = _TestRequestHandler();
          shared.onRequest(RequestOptions(path: '/api/users'), next);
          expect(next.result.passed, isTrue, reason: 'one recorded failure would have opened the circuit');
        });
      });

      // A pin mismatch fails the TLS handshake before the request reaches the server, so it says nothing about the
      // endpoint's health. Counted as failures, five of them opened the circuit, and the user then saw "Circuit
      // Breaker Open" instead of the insecure-connection message.
      test('should pass a certificate pin mismatch through without recording a failure', () {
        final shared = ResilienceInterceptor(failureThreshold: 1, cooldownDuration: const Duration(hours: 1));
        final err = DioException(
          requestOptions: RequestOptions(path: '/api/users', method: 'GET'),
          error: const CertificatePinningException('api.example.test', 443),
        );

        final result = _captureOnErrorSync(shared.forDio(Dio()), err);
        expect(result.passed, isTrue);

        final next = _TestRequestHandler();
        shared.onRequest(RequestOptions(path: '/api/users'), next);
        expect(next.result.passed, isTrue, reason: 'one recorded failure would have opened the circuit');
      });
    });

    // Every other TLS failure fails the handshake before the request reaches the server as well, and must reach the
    // user as the insecure-connection message, not as "Circuit Breaker Open" once five of them opened the circuit.
    group('onError with a TLS failure', () {
      final failures = <String, DioException Function(RequestOptions)>{
        'a HandshakeException': (options) => DioException(
          requestOptions: options,
          error: const HandshakeException('Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED)'),
        ),
        'a CertificateException': (options) =>
            DioException(requestOptions: options, error: const CertificateException('certificate rejected')),
        'a bad certificate': (options) => DioException.badCertificate(requestOptions: options),
      };
      // The network can change between two attempts, so a retry can fail the handshake as well.
      test('should not count a TLS failure of a retry against the circuit breaker', () async {
        final adapter = _FakeHttpClientAdapter([
          503,
          const HandshakeException('Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED)'),
        ]);
        final resilience = ResilienceInterceptor(
          maxRetries: 1,
          baseDelay: Duration.zero,
          maxJitter: Duration.zero,
          failureThreshold: 10,
          cooldownDuration: const Duration(hours: 1),
        );
        final dio = Dio(BaseOptions(baseUrl: 'https://test.api'))..httpClientAdapter = adapter;
        dio.interceptors.add(resilience.forDio(dio));

        await expectLater(
          dio.get<String>('/api/users'),
          throwsA(isA<DioException>().having((e) => e.error, 'error', isA<HandshakeException>())),
        );
        expect(adapter.requestCount, 2);
        expect(resilience.circuitBreakers['/api/users']?.failureCount, 1, reason: 'only the 503 may count');
      });

      for (final MapEntry(key: failure, value: build) in failures.entries) {
        test('should pass $failure through without recording a failure', () {
          final shared = ResilienceInterceptor(failureThreshold: 1, cooldownDuration: const Duration(hours: 1));

          final result = _captureOnErrorSync(
            shared.forDio(Dio()),
            build(RequestOptions(path: '/api/users', method: 'GET')),
          );
          expect(result.passed, isTrue);

          final next = _TestRequestHandler();
          shared.onRequest(RequestOptions(path: '/api/users'), next);
          expect(next.result.passed, isTrue, reason: 'one recorded failure would have opened the circuit');
        });
      }
    });

    // A retry sends the request again, so it is safe only when a second copy cannot change anything on the
    // server: an idempotent method, or a POST or PATCH whose Idempotency-Key the retry sends again.
    group('retry by HTTP method', () {
      for (final method in ['GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE']) {
        test('retries $method requests after a 503', () async {
          final adapter = _FakeHttpClientAdapter([503, 200]);

          final response = await _retryingDio(adapter).request<String>('/api/users', options: Options(method: method));

          expect(response.statusCode, 200);
          expect(adapter.requestCount, 2);
        });
      }

      for (final method in ['POST', 'PATCH']) {
        test('does not retry $method requests without an Idempotency-Key after a 503', () async {
          final adapter = _FakeHttpClientAdapter([503, 200]);

          await expectLater(
            _retryingDio(adapter).request<String>('/api/users', options: Options(method: method)),
            throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 503)),
          );
          expect(adapter.requestCount, 1);
        });

        test('retries $method requests that carry an Idempotency-Key after a 503', () async {
          final adapter = _FakeHttpClientAdapter([503, 200]);

          final response = await _retryingDio(adapter).request<String>(
            '/api/users',
            options: Options(method: method, headers: {'Idempotency-Key': 'order-42'}),
          );

          expect(response.statusCode, 200);
          expect(adapter.requestCount, 2);
        });
      }

      test('does not retry a POST without an Idempotency-Key after a receive timeout', () {
        fakeAsync((async) {
          final interceptor = ResilienceInterceptor(
            failureThreshold: 10,
            cooldownDuration: const Duration(hours: 1),
            maxRetries: 3,
          ).forDio(Dio());
          final err = DioException.receiveTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: RequestOptions(path: '/api/users', method: 'POST'),
          );

          // Passed on at once instead of waiting for a retry's backoff delay.
          final result = _captureOnErrorSync(interceptor, err);
          expect(result.passed, isTrue);
        });
      });

      // A refused connection on dart:io proves the POST was never sent, but on web dio reports every XMLHttpRequest
      // network failure, including one after the server received the request, as the same connection error. One
      // rule applies on every platform, so a POST without an Idempotency-Key is not retried here either.
      test('does not retry a POST without an Idempotency-Key after a connection error', () {
        fakeAsync((async) {
          final interceptor = ResilienceInterceptor(
            failureThreshold: 10,
            cooldownDuration: const Duration(hours: 1),
            maxRetries: 3,
          ).forDio(Dio());
          final options = RequestOptions(path: '/api/users', method: 'POST');
          const refused = SocketException('Connection refused');
          final err = DioException.connectionError(requestOptions: options, reason: refused.message, error: refused);

          final result = _captureOnErrorSync(interceptor, err);
          expect(result.passed, isTrue);
        });
      });
    });

    group('per-endpoint circuit breakers', () {
      test('should maintain separate breakers for different endpoints', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 2,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        // Trip the circuit for /api/users
        for (int i = 0; i < 2; i++) {
          final err = DioException(
            requestOptions: RequestOptions(path: '/api/users'),
            type: DioExceptionType.connectionTimeout,
          );
          _fireOnError(interceptor, err);
        }

        // /api/users should be open
        final usersResult = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(usersResult.rejected, isTrue);

        // /api/products should still be closed
        final productsResult = await _captureOnRequest(interceptor, RequestOptions(path: '/api/products'));
        expect(productsResult.passed, isTrue);
      });

      test('should strip numeric IDs from endpoint key', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 2,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        // Failures for /api/users/123 should affect /api/users/456 too
        final err1 = DioException(
          requestOptions: RequestOptions(path: '/api/users/123'),
          type: DioExceptionType.connectionTimeout,
        );
        _fireOnError(interceptor, err1);

        final err2 = DioException(
          requestOptions: RequestOptions(path: '/api/users/456'),
          type: DioExceptionType.connectionTimeout,
        );
        _fireOnError(interceptor, err2);

        // Both share the same breaker (/api/users), so it should now be open
        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users/789'));
        expect(result.rejected, isTrue);
      });
    });

    group('retry logic', () {
      test('should give up after maxRetries exhausted', () async {
        final interceptor = ResilienceInterceptor(
          maxRetries: 2,
          baseDelay: const Duration(milliseconds: 1),
          maxJitter: Duration.zero,
          failureThreshold: 100,
          cooldownDuration: const Duration(hours: 1),
        );

        final options = RequestOptions(path: '/api/test');
        options.extra['_retryAttempt'] = 2; // Already at max retries

        final err = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 502),
        );

        final result = _captureOnErrorSync(interceptor, err);
        // Should pass through (give up) since max retries exhausted
        expect(result.passed, isTrue);
      });

      test('should not retry non-retryable 500 server errors', () async {
        final interceptor = ResilienceInterceptor(failureThreshold: 100, maxRetries: 3);
        final options = RequestOptions(path: '/api/test');
        final err = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 500),
        );

        // 500 is not in the retryable set (only 502, 503, 504)
        final result = _captureOnErrorSync(interceptor, err);
        expect(result.passed, isTrue);
      });

      test('should consider 504 as retryable', () async {
        final adapter = _FakeHttpClientAdapter([504, 200]);

        final response = await _retryingDio(adapter).get<String>('/api/test');

        expect(response.statusCode, 200);
        expect(adapter.requestCount, 2);
      });

      test('should consider sendTimeout as retryable', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 2,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        for (int i = 0; i < 2; i++) {
          final err = DioException(
            requestOptions: RequestOptions(path: '/api/test'),
            type: DioExceptionType.sendTimeout,
          );
          _fireOnError(interceptor, err);
        }

        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/test'));
        expect(result.rejected, isTrue);
      });

      test('should consider receiveTimeout as retryable', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 2,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        for (int i = 0; i < 2; i++) {
          final err = DioException(
            requestOptions: RequestOptions(path: '/api/test'),
            type: DioExceptionType.receiveTimeout,
          );
          _fireOnError(interceptor, err);
        }

        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/test'));
        expect(result.rejected, isTrue);
      });
    });

    group('circuitBreakers getter', () {
      test('should return an unmodifiable map', () {
        final interceptor = ResilienceInterceptor();
        final breakers = interceptor.circuitBreakers;
        expect(() => breakers['test'] = CircuitBreaker(), throwsUnsupportedError);
      });

      test('should return empty map when no requests have been made', () {
        final interceptor = ResilienceInterceptor();
        expect(interceptor.circuitBreakers, isEmpty);
      });

      test('should contain registered endpoints after requests', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 10,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        // Trigger breaker creation via onRequest
        await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        await _captureOnRequest(interceptor, RequestOptions(path: '/api/products'));

        final breakers = interceptor.circuitBreakers;
        expect(breakers, hasLength(2));
        expect(breakers.containsKey('/api/users'), isTrue);
        expect(breakers.containsKey('/api/products'), isTrue);
      });
    });

    group('resetAll', () {
      test('should reset all breakers to closed state', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 2,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        // Trip /api/users breaker
        for (int i = 0; i < 2; i++) {
          _fireOnError(
            interceptor,
            DioException(
              requestOptions: RequestOptions(path: '/api/users'),
              type: DioExceptionType.connectionTimeout,
            ),
          );
        }

        // Trip /api/products breaker
        for (int i = 0; i < 2; i++) {
          _fireOnError(
            interceptor,
            DioException(
              requestOptions: RequestOptions(path: '/api/products'),
              type: DioExceptionType.connectionTimeout,
            ),
          );
        }

        // Verify both are open
        var usersResult = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(usersResult.rejected, isTrue);
        var productsResult = await _captureOnRequest(interceptor, RequestOptions(path: '/api/products'));
        expect(productsResult.rejected, isTrue);

        // Reset all
        interceptor.resetAll();

        // Verify both are closed again
        usersResult = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(usersResult.passed, isTrue);
        productsResult = await _captureOnRequest(interceptor, RequestOptions(path: '/api/products'));
        expect(productsResult.passed, isTrue);
      });

      test('should set all breakers state to closed', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 2,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        // Trip a breaker
        for (int i = 0; i < 2; i++) {
          _fireOnError(
            interceptor,
            DioException(
              requestOptions: RequestOptions(path: '/api/users'),
              type: DioExceptionType.connectionTimeout,
            ),
          );
        }

        interceptor.resetAll();

        for (final breaker in interceptor.circuitBreakers.values) {
          expect(breaker.state, CircuitBreakerState.closed);
          expect(breaker.failureCount, 0);
        }
      });
    });

    group('singleton instance', () {
      test('should return the same instance', () {
        final a = ResilienceInterceptor.instance;
        final b = ResilienceInterceptor.instance;
        expect(identical(a, b), isTrue);
      });
    });

    group('retry transport', () {
      test('forDio shares circuit breakers with the instance it was made from', () {
        final shared = ResilienceInterceptor(
          failureThreshold: 1,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );
        final bound = shared.forDio(Dio());

        _fireOnError(
          bound,
          DioException(
            requestOptions: RequestOptions(path: '/api/users'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(shared.circuitBreakers['/api/users']?.state, CircuitBreakerState.open);
      });

      test('forDio sends the retry through the adapter of that Dio', () async {
        final adapter = _FakeHttpClientAdapter([503, 200]);
        final dio = Dio(BaseOptions(baseUrl: 'https://test.api'))..httpClientAdapter = adapter;
        dio.interceptors.add(
          ResilienceInterceptor(
            maxRetries: 1,
            baseDelay: Duration.zero,
            maxJitter: Duration.zero,
            failureThreshold: 10,
            cooldownDuration: const Duration(hours: 1),
          ).forDio(dio),
        );

        final response = await dio.get<String>('/api/users');

        expect(response.statusCode, 200);
        expect(adapter.requestCount, 2);
      });

      test('an instance not made by forDio rejects a retry instead of sending it', () async {
        final adapter = _FakeHttpClientAdapter([503]);
        final dio = Dio(BaseOptions(baseUrl: 'https://test.api'))..httpClientAdapter = adapter;
        dio.interceptors.add(
          ResilienceInterceptor(
            maxRetries: 1,
            baseDelay: Duration.zero,
            maxJitter: Duration.zero,
            failureThreshold: 10,
            cooldownDuration: const Duration(hours: 1),
          ),
        );

        await expectLater(
          dio.get<String>('/api/users'),
          throwsA(isA<DioException>().having((e) => e.error, 'error', isA<StateError>())),
        );
        expect(adapter.requestCount, 1);
      });
    });

    group('endpoint key extraction', () {
      test('should extract base path without IDs', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 1,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        // Fail on /api/users/123
        final err = DioException(
          requestOptions: RequestOptions(path: '/api/users/123'),
          type: DioExceptionType.connectionTimeout,
        );
        _fireOnError(interceptor, err);

        // Should be open for /api/users (same endpoint key)
        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(result.rejected, isTrue);
      });

      test('should handle UUID-like segments as IDs', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 1,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        // Fail on path with UUID
        final err = DioException(
          requestOptions: RequestOptions(path: '/api/users/550e8400-e29b-41d4-a716-446655440000'),
          type: DioExceptionType.connectionTimeout,
        );
        _fireOnError(interceptor, err);

        // Should be open for /api/users
        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/api/users'));
        expect(result.rejected, isTrue);
      });

      // GET /admin/users/{login} carries the login, which registration sets to the user's email. The breaker keys
      // are listed on the system dashboard, so the email must not become part of one.
      for (final login in ['jane.doe@example.com', 'jane.doe%40example.com']) {
        test('should handle an email segment ($login) as an ID', () async {
          final interceptor = ResilienceInterceptor(
            failureThreshold: 1,
            cooldownDuration: const Duration(hours: 1),
            maxRetries: 0,
          );

          final err = DioException(
            requestOptions: RequestOptions(path: '/admin/users/$login'),
            type: DioExceptionType.connectionTimeout,
          );
          _fireOnError(interceptor, err);

          expect(interceptor.circuitBreakers.keys, ['/admin/users']);
          final result = await _captureOnRequest(interceptor, RequestOptions(path: '/admin/users'));
          expect(result.rejected, isTrue);
        });
      }

      test('should handle empty path', () async {
        final interceptor = ResilienceInterceptor(
          failureThreshold: 1,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );

        final err = DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionTimeout,
        );
        _fireOnError(interceptor, err);

        final result = await _captureOnRequest(interceptor, RequestOptions(path: '/'));
        expect(result.rejected, isTrue);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Captures the result of calling onRequest on the interceptor.
Future<_InterceptorResult> _captureOnRequest(ResilienceInterceptor interceptor, RequestOptions options) async {
  final handler = _TestRequestHandler();
  interceptor.onRequest(options, handler);
  return handler.result;
}

/// Captures the result of calling onResponse on the interceptor.
Future<_InterceptorResult> _captureOnResponse(ResilienceInterceptor interceptor, Response response) async {
  final handler = _TestResponseHandler();
  interceptor.onResponse(response, handler);
  return handler.result;
}

/// Fires onError synchronously (doesn't wait for retry).
_InterceptorErrorResult _captureOnErrorSync(ResilienceInterceptor interceptor, DioException err) {
  final handler = _TestErrorHandler();
  interceptor.onError(err, handler);
  return handler.result;
}

/// Fires onError without capturing result (fire-and-forget for circuit breaker trips).
void _fireOnError(ResilienceInterceptor interceptor, DioException err) {
  final handler = _TestErrorHandler();
  interceptor.onError(err, handler);
}

/// A Dio that retries once through [adapter], without a backoff delay.
Dio _retryingDio(_FakeHttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.api'))..httpClientAdapter = adapter;
  dio.interceptors.add(
    ResilienceInterceptor(
      maxRetries: 1,
      baseDelay: Duration.zero,
      maxJitter: Duration.zero,
      failureThreshold: 10,
      cooldownDuration: const Duration(hours: 1),
    ).forDio(dio),
  );
  return dio;
}

class _InterceptorResult {
  final bool passed;
  final bool rejected;
  final DioException? rejectError;

  _InterceptorResult({this.passed = false, this.rejected = false, this.rejectError});
}

class _InterceptorErrorResult {
  final bool passed;
  final bool resolved;
  final bool rejected;

  _InterceptorErrorResult({this.passed = false, this.resolved = false, this.rejected = false});
}

class _TestRequestHandler extends RequestInterceptorHandler {
  _InterceptorResult result = _InterceptorResult();

  @override
  void next(RequestOptions requestOptions) {
    result = _InterceptorResult(passed: true);
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    result = _InterceptorResult(rejected: true, rejectError: error);
  }

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {
    result = _InterceptorResult(passed: true);
  }
}

class _TestResponseHandler extends ResponseInterceptorHandler {
  _InterceptorResult result = _InterceptorResult();

  @override
  void next(Response response) {
    result = _InterceptorResult(passed: true);
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    result = _InterceptorResult(rejected: true, rejectError: error);
  }

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {
    result = _InterceptorResult(passed: true);
  }
}

/// Counts requests and answers each one with the next queued status code, or throws the next queued error.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._replies);

  final List<Object> _replies;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    return switch (_replies.removeAt(0)) {
      final int statusCode => ResponseBody.fromString('', statusCode),
      final Object error => throw error,
    };
  }

  @override
  void close({bool force = false}) {}
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  _InterceptorErrorResult result = _InterceptorErrorResult();

  @override
  void next(DioException error) {
    result = _InterceptorErrorResult(passed: true);
  }

  @override
  void resolve(Response response) {
    result = _InterceptorErrorResult(resolved: true);
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    result = _InterceptorErrorResult(rejected: true);
  }
}
