import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';

/// Dio interceptor that combines **smart retry** with a **circuit breaker**
/// to improve resilience against transient failures.
///
/// **Retry logic:**
/// - Retryable errors: timeout, connection error, HTTP 502/503/504.
/// - Non-retryable: 400, 401, 403, 404, 422 pass through immediately.
/// - Max retries: 3, exponential backoff with jitter (200ms base).
/// - Respects the `Retry-After` header when present.
///
/// **Circuit breaker logic:**
/// - Each endpoint (path prefix) gets its own [CircuitBreaker] instance.
/// - Before a request: if the circuit is OPEN, rejects immediately with
///   [CircuitBreakerOpenException].
/// - After a response: records success or failure.
///
/// Must be added to the interceptor chain AFTER [AuthInterceptor] so that
/// the auth token is present, and BEFORE [MockInterceptor] so that
/// resilience logic wraps the actual network call.
class ResilienceInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('ResilienceInterceptor');
  static final _random = Random();

  static final ResilienceInterceptor _instance = ResilienceInterceptor();
  static ResilienceInterceptor get instance => _instance;

  /// Maximum number of retry attempts for retryable errors.
  final int maxRetries;

  /// Base delay for exponential backoff (doubles each attempt).
  final Duration baseDelay;

  /// Maximum random jitter added to each backoff delay.
  final Duration maxJitter;

  /// Per-endpoint circuit breakers.
  final Map<String, CircuitBreaker> _breakers = {};

  /// Unmodifiable view of per-endpoint circuit breakers for monitoring.
  Map<String, CircuitBreaker> get circuitBreakers => Map.unmodifiable(_breakers);

  /// Reset all circuit breakers to closed state.
  void resetAll() {
    for (final breaker in _breakers.values) {
      breaker.reset();
    }
    _log.info('All circuit breakers reset');
  }

  /// Circuit breaker configuration.
  final int failureThreshold;
  final Duration cooldownDuration;

  ResilienceInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 200),
    this.maxJitter = const Duration(milliseconds: 100),
    this.failureThreshold = 5,
    this.cooldownDuration = const Duration(seconds: 30),
  });

  // ---------------------------------------------------------------------------
  // Interceptor hooks
  // ---------------------------------------------------------------------------

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final endpointKey = _extractEndpointKey(options.path);
    final breaker = _getBreaker(endpointKey);

    if (!breaker.allowRequest) {
      _log.warn('Circuit OPEN for endpoint "{}" — rejecting request {} {}', [
        endpointKey,
        options.method,
        options.path,
      ]);

      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: CircuitBreakerOpenException(endpointKey),
          message: 'Circuit breaker is open for endpoint: $endpointKey',
        ),
      );
      return;
    }

    _log.debug('Circuit {} for endpoint "{}" — allowing request {} {}', [
      breaker.state.name,
      endpointKey,
      options.method,
      options.path,
    ]);

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final endpointKey = _extractEndpointKey(response.requestOptions.path);
    final breaker = _getBreaker(endpointKey);
    breaker.recordSuccess();

    _log.debug('Success for endpoint "{}" — circuit reset to closed', [endpointKey]);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final endpointKey = _extractEndpointKey(err.requestOptions.path);
    final breaker = _getBreaker(endpointKey);

    // If this is already a circuit breaker rejection, pass through.
    if (err.error is CircuitBreakerOpenException) {
      handler.next(err);
      return;
    }

    // Non-retryable errors: record failure and pass through immediately.
    if (!_isRetryable(err)) {
      // Client errors (4xx) should not trip the circuit breaker.
      if (!_isClientError(err)) {
        breaker.recordFailure();
        _log.debug('Non-retryable server error for endpoint "{}" — failure count: {}', [
          endpointKey,
          breaker.failureCount,
        ]);
      }
      handler.next(err);
      return;
    }

    // Record the failure for retryable errors.
    breaker.recordFailure();
    _log.debug('Retryable error for endpoint "{}" — failure count: {}', [endpointKey, breaker.failureCount]);

    // Attempt retry with backoff.
    _retryRequest(err, handler, endpointKey);
  }

  // ---------------------------------------------------------------------------
  // Retry logic
  // ---------------------------------------------------------------------------

  Future<void> _retryRequest(DioException err, ErrorInterceptorHandler handler, String endpointKey) async {
    final options = err.requestOptions;
    final attempt = (options.extra['_retryAttempt'] as int?) ?? 0;

    if (attempt >= maxRetries) {
      _log.warn('Max retries ({}) exhausted for {} {} — giving up', [maxRetries, options.method, options.path]);
      handler.next(err);
      return;
    }

    final nextAttempt = attempt + 1;
    final delay = _calculateDelay(err, nextAttempt);

    _log.info('Retry {}/{} for {} {} in {}ms', [
      nextAttempt,
      maxRetries,
      options.method,
      options.path,
      delay.inMilliseconds,
    ]);

    await Future<void>.delayed(delay);

    // Check circuit breaker again before retrying.
    final breaker = _getBreaker(endpointKey);
    if (!breaker.allowRequest) {
      _log.warn('Circuit opened during retry backoff for "{}" — aborting retry', [endpointKey]);
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: CircuitBreakerOpenException(endpointKey),
          message: 'Circuit breaker opened during retry for endpoint: $endpointKey',
        ),
      );
      return;
    }

    // Clone the request with the updated retry attempt counter.
    options.extra['_retryAttempt'] = nextAttempt;

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: options.baseUrl,
          connectTimeout: options.connectTimeout,
          receiveTimeout: options.receiveTimeout,
          headers: options.headers,
          responseType: options.responseType,
        ),
      );

      final response = await dio.fetch<dynamic>(options);
      breaker.recordSuccess();
      _log.info('Retry {}/{} succeeded for {} {}', [nextAttempt, maxRetries, options.method, options.path]);
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          data: response.data,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          headers: response.headers,
        ),
      );
    } on DioException catch (retryErr) {
      breaker.recordFailure();

      if (_isRetryable(retryErr) && nextAttempt < maxRetries) {
        retryErr.requestOptions.extra['_retryAttempt'] = nextAttempt;
        _retryRequest(retryErr, handler, endpointKey);
      } else {
        _log.warn('Retry {}/{} failed for {} {} — {}', [
          nextAttempt,
          maxRetries,
          options.method,
          options.path,
          retryErr.message ?? retryErr.type.name,
        ]);
        handler.next(retryErr);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Extract a stable endpoint key from a request path.
  ///
  /// Strips trailing path segments that look like IDs (numeric, UUIDs, etc.)
  /// so that `/admin/users/123` and `/admin/users/456` share the same breaker.
  String _extractEndpointKey(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '/';

    // Remove trailing segments that look like IDs.
    while (segments.length > 1 && _looksLikeId(segments.last)) {
      segments.removeLast();
    }

    return '/${segments.join('/')}';
  }

  /// Heuristic: a segment looks like an ID if it is purely numeric or matches
  /// a UUID-like pattern (contains dashes and hex characters).
  bool _looksLikeId(String segment) {
    if (RegExp(r'^\d+$').hasMatch(segment)) return true;
    if (RegExp(r'^[0-9a-fA-F-]{8,}$').hasMatch(segment)) return true;
    return false;
  }

  /// Get or create a circuit breaker for the given endpoint key.
  CircuitBreaker _getBreaker(String endpointKey) {
    return _breakers.putIfAbsent(
      endpointKey,
      () => CircuitBreaker(failureThreshold: failureThreshold, cooldownDuration: cooldownDuration),
    );
  }

  /// Whether an error is retryable (transient).
  bool _isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        return statusCode == 502 || statusCode == 503 || statusCode == 504;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Whether an error is a client error (4xx) that should NOT trip the breaker.
  bool _isClientError(DioException err) {
    if (err.type != DioExceptionType.badResponse) return false;
    final statusCode = err.response?.statusCode ?? 0;
    return statusCode >= 400 && statusCode < 500;
  }

  /// Calculate the delay before the next retry attempt.
  ///
  /// Uses exponential backoff: `baseDelay * 2^(attempt-1)` plus random jitter.
  /// Respects the `Retry-After` header if present.
  Duration _calculateDelay(DioException err, int attempt) {
    // Check for Retry-After header.
    final retryAfter = err.response?.headers.value('retry-after');
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds);
      }
    }

    // Exponential backoff with jitter.
    final exponentialMs = baseDelay.inMilliseconds * pow(2, attempt - 1);
    final jitterMs = _random.nextInt(maxJitter.inMilliseconds + 1);
    return Duration(milliseconds: exponentialMs.toInt() + jitterMs);
  }
}
