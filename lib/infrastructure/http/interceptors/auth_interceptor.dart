import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// Injects JWT Bearer token into every outgoing request.
///
/// Token is sourced from [AppLocalStorageCached.jwtToken] (populated on login
/// by [AppLocalStorageCached.loadCache]) so that the interceptor stays
/// synchronous in the fast path. Falls back to [ISecureStorage] for production
/// reads when the cache is cold.
class AuthInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('AuthInterceptor');

  AuthInterceptor({ISecureStorage? secureStorage}) : _secureStorage = secureStorage ?? FlutterSecureStorageAdapter();

  final ISecureStorage _secureStorage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Use the in-memory cache first (populated after persist / loadCache).
    // This avoids platform-channel calls on every request and works in tests
    // where the plugin is unavailable.
    final jwtToken = AppLocalStorageCached.jwtToken ?? await _secureStorage.read(SecureStorageKeys.jwtToken.key);
    if (jwtToken != null) {
      options.headers['Authorization'] = 'Bearer $jwtToken';
    }
    _log.debug('Request [{}] {} (auth: {})', [options.method, options.path, jwtToken != null]);
    handler.next(options);
  }
}
