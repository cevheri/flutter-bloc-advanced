import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
import 'package:flutter_bloc_advance/infrastructure/http/public_endpoint.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';

/// Injects JWT Bearer token into every outgoing request, except a request
/// to a public endpoint ([isPublicEndpoint]).
///
/// Reads from [ISecureStorage] on every request. There is no in-memory
/// cache: the only data source for the JWT is the secure store, which
/// gives us a single, authoritative answer and removes the need for
/// downstream consumers (repository persist, token refresh, logout) to
/// keep a parallel cache field consistent.
///
/// It records on every request that is not to a public endpoint the
/// [SessionGeneration] the request goes out under, which
/// `TokenRefreshInterceptor` checks before it sends the request again or
/// refreshes the session for a 401.
class AuthInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('AuthInterceptor');

  AuthInterceptor({ISecureStorage? secureStorage}) : _secureStorage = secureStorage ?? FlutterSecureStorageAdapter();

  final ISecureStorage _secureStorage;

  /// The [RequestOptions.extra] key under which [onRequest] records the [SessionGeneration] a request is sent under.
  static const sessionGenerationKey = '_sessionGeneration';

  /// The [SessionGeneration] that [onRequest] recorded for [options], or null when it recorded none: for a request to a
  /// public endpoint, or one that did not go through it.
  static int? sessionGenerationOf(RequestOptions options) => options.extra[sessionGenerationKey] as int?;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // A public endpoint (sign-in, OTP, registration, password reset, token
    // refresh, and the app config that the lifecycle checks read before
    // sign-in) needs no session, so it never gets the stored token. That
    // token can be a stale one left by an expired session, and a server
    // that checks every token it receives rejects such a request even
    // where none is needed.
    if (isPublicEndpoint(options)) {
      _log.debug('Request [{}] {} (public endpoint, no token)', [options.method, options.path]);
      handler.next(options);
      return;
    }
    // Recorded before the token is read, so a 401 for this request can tell that the session it was sent under ended
    // since, even when the wipe started while the token was read.
    options.extra[sessionGenerationKey] = SessionGeneration.current;
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
    _log.debug('Request [{}] {} (auth: {}, token: {})', [options.method, options.path, hasAuth, maskToken(jwtToken)]);
    handler.next(options);
  }
}
