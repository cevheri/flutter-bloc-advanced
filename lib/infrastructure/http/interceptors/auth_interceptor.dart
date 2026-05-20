import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// Injects JWT Bearer token into every outgoing request.
///
/// Reads from [ISecureStorage] on every request. There is no in-memory
/// cache: the only data source for the JWT is the secure store, which
/// gives us a single, authoritative answer and removes the need for
/// downstream consumers (repository persist, token refresh, logout) to
/// keep a parallel cache field consistent.
class AuthInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('AuthInterceptor');

  AuthInterceptor({ISecureStorage? secureStorage}) : _secureStorage = secureStorage ?? FlutterSecureStorageAdapter();

  final ISecureStorage _secureStorage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // ISecureStorage.read can throw on platform / decryption failure.
    // If that happens, send the request anonymously rather than failing
    // the request itself — the downstream 401 path will trigger logout
    // / re-auth, which is the right user-visible outcome. Crashing the
    // interceptor would break every HTTP call until app restart.
    String? jwtToken;
    try {
      jwtToken = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
    } catch (e) {
      _log.warn('secure read failed for {}; sending request without Authorization: {}', [options.path, e]);
    }
    final hasAuth = jwtToken != null && jwtToken.isNotEmpty;
    if (hasAuth) {
      options.headers['Authorization'] = 'Bearer $jwtToken';
    }
    _log.debug('Request [{}] {} (auth: {}, token: {})', [
      options.method,
      options.path,
      hasAuth,
      LogSanitizer.maskToken(jwtToken),
    ]);
    handler.next(options);
  }
}
