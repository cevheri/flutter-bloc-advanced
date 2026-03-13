import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Structured request/response logging via AppLogger.
class LoggingInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('Http');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.debug('{} {} (headers: {})', [options.method, options.uri, options.headers.keys.join(', ')]);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.debug('{} {} -> {} (length: {})', [
      response.requestOptions.method,
      response.requestOptions.path,
      response.statusCode,
      response.data?.toString().length ?? 0,
    ]);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.error('{} {} -> ERROR: {} {}', [
      err.requestOptions.method,
      err.requestOptions.path,
      err.type.name,
      err.message ?? '',
    ]);
    handler.next(err);
  }
}
