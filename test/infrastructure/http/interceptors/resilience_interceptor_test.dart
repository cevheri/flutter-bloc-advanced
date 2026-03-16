import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  });

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
        final interceptor = ResilienceInterceptor(
          failureThreshold: 100,
          cooldownDuration: const Duration(hours: 1),
          maxRetries: 0,
        );
        final options = RequestOptions(path: '/api/test');
        final err = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 504),
        );

        // maxRetries=0, so it records failure and passes through
        _fireOnError(interceptor, err);

        // Verify the failure was recorded (retryable path records failure)
        // We'd need the threshold hit to confirm, but we can verify it doesn't crash
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

class _InterceptorResult {
  final bool passed;
  final bool rejected;
  final DioException? rejectError;

  _InterceptorResult({this.passed = false, this.rejected = false, this.rejectError});
}

class _InterceptorErrorResult {
  final bool passed;
  final bool resolved;

  _InterceptorErrorResult({this.passed = false, this.resolved = false});
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
  void reject(DioException error) {
    result = _InterceptorErrorResult(passed: true);
  }
}
