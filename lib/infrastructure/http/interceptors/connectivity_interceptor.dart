import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/cache_interceptor.dart';

/// Exception thrown when a request is attempted while offline.
///
/// [ConnectivityInterceptor] puts it in the `error` of the [DioException] it rejects such a request with, so the
/// interceptors after it can tell that the device is offline without matching message text.
class ConnectivityException implements Exception {
  final String message;

  const ConnectivityException([this.message = 'No internet connection']);

  @override
  String toString() => 'ConnectivityException: $message';
}

/// Dio interceptor that checks connectivity before sending requests.
///
/// Must be added as the FIRST interceptor in the chain so that requests
/// are rejected immediately when offline, instead of waiting for a timeout.
///
/// The rejection is a connection error that runs every onError handler of the
/// chain (`callFollowingErrorInterceptor: true`), as a request that fails to
/// connect does: `CacheInterceptor` answers a GET from its cache, and the dev
/// console and logging record a request it cannot answer. Its error is a
/// [ConnectivityException], so `ResilienceInterceptor` neither retries it nor
/// counts it against the endpoint's circuit breaker.
///
/// A GET that [CacheInterceptor] answers from the cache alone
/// (`CachePolicy.cacheOnly`) is let through: it never reaches the network.
///
/// The connectivity check is injected via [statusProvider] so tests can
/// deterministically exercise the offline-rejection branch without
/// mutating the global [ConnectivityService] singleton (fixes #65).
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor({ConnectivityStatus Function()? statusProvider})
    : _statusProvider = statusProvider ?? (() => ConnectivityService.instance.currentStatus);

  static final _log = AppLogger.getLogger('ConnectivityInterceptor');

  final ConnectivityStatus Function() _statusProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final status = _statusProvider();

    if (status == ConnectivityStatus.offline && !CacheInterceptor.isCacheOnly(options)) {
      _log.warn('Request blocked — device is offline: {} {}', [options.method, options.path]);
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const ConnectivityException(),
          message: 'No internet connection. Please check your network and try again.',
        ),
        true,
      );
      return;
    }

    handler.next(options);
  }
}
