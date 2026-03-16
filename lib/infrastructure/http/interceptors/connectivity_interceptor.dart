import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';

/// Exception thrown when a request is attempted while offline.
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
class ConnectivityInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('ConnectivityInterceptor');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final status = ConnectivityService.instance.currentStatus;

    if (status == ConnectivityStatus.offline) {
      _log.warn('Request blocked — device is offline: {} {}', [options.method, options.path]);
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const ConnectivityException(),
          message: 'No internet connection. Please check your network and try again.',
        ),
      );
      return;
    }

    handler.next(options);
  }
}
