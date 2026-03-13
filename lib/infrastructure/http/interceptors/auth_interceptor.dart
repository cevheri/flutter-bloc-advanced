import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

/// Injects JWT Bearer token into every outgoing request.
class AuthInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('AuthInterceptor');

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final jwtToken = await AppLocalStorage().read(StorageKeys.jwtToken.name);
    if (jwtToken != null) {
      options.headers['Authorization'] = 'Bearer $jwtToken';
    }
    _log.debug('Request [{}] {} (auth: {})', [options.method, options.path, jwtToken != null]);
    handler.next(options);
  }
}
