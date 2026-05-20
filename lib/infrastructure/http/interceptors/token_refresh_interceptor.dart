import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// Callback signature for notifying the app layer that the session has expired
/// and the user must be logged out.
///
/// By using a callback we avoid importing anything from `app/` in the
/// infrastructure layer.
typedef OnSessionExpired = void Function();

/// Intercepts 401 responses and attempts a silent token refresh.
///
/// Extends [QueuedInterceptor] so dio queues concurrent 401s, but the
/// refresh request itself is also coalesced via a shared in-flight
/// [Future]. When several requests fail with 401 around the same time
/// the first one starts the refresh; the rest await the same Future
/// and retry with the already-rotated token instead of triggering a
/// refresh storm against `/api/token/refresh`.
///
/// Interceptor order (must come AFTER [AuthInterceptor]):
/// ```
/// AuthInterceptor -> TokenRefreshInterceptor -> MockInterceptor? -> ...
/// ```
class TokenRefreshInterceptor extends QueuedInterceptor {
  static final _log = AppLogger.getLogger('TokenRefreshInterceptor');

  final Dio _dio;
  final OnSessionExpired? _onSessionExpired;
  final ISecureStorage _secureStorage;

  /// Shared in-flight refresh. Non-null while a refresh is in progress;
  /// concurrent 401s await the same Future. Cleared on completion (success
  /// or failure) so the next refresh window can start a fresh attempt.
  Future<String?>? _inFlightRefresh;

  TokenRefreshInterceptor({required Dio dio, OnSessionExpired? onSessionExpired, ISecureStorage? secureStorage})
    : _dio = dio,
      _onSessionExpired = onSessionExpired,
      _secureStorage = secureStorage ?? FlutterSecureStorageAdapter();

  /// Marker placed on [RequestOptions.extra] for requests that have
  /// already been retried after a refresh. A second 401 on the same
  /// request short-circuits to logout instead of attempting another
  /// refresh — prevents infinite refresh loops when the backend keeps
  /// rejecting freshly-rotated tokens (revoked session, clock skew,
  /// backend bug, etc.).
  static const _retriedAfterRefresh = '_tokenRefresh_retried';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 Unauthorized responses
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Avoid refreshing on the refresh endpoint itself to prevent infinite loops
    final requestPath = err.requestOptions.path;
    if (requestPath.contains('/api/token/refresh')) {
      _log.warn('Refresh endpoint returned 401 — session expired');
      _triggerLogout();
      handler.next(err);
      return;
    }

    // Second 401 on the same request after a refresh+retry round
    // already happened — refusing to refresh again. The newly-rotated
    // token is being rejected; another refresh would just produce
    // another rejected token. Surface the failure and log out.
    if (err.requestOptions.extra[_retriedAfterRefresh] == true) {
      _log.warn('401 again after refresh+retry for {} — giving up to avoid loop', [requestPath]);
      _triggerLogout();
      handler.next(err);
      return;
    }

    _log.debug('401 received for {} — checking refresh state', [requestPath]);

    // Stale-header short-circuit: if the JWT has already been rotated
    // since this request was sent (e.g. a previous refresh completed
    // while this request was in flight), just retry with the current
    // token. Avoids back-to-back refresh calls when a serialised wave
    // of 401s arrives after the first refresh completes.
    //
    // ISecureStorage.read can throw on platform / decryption failure
    // (contract from the secure-storage refactor). Treat that as
    // "optimization unavailable" and fall through to the normal
    // refresh path — letting the read escape would break the request
    // pipeline.
    String? currentToken;
    try {
      currentToken = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
    } catch (e) {
      _log.warn('Stale-header check skipped — secure read failed: {}', [e]);
    }
    // Dio headers are Map<String, dynamic>; defensive narrowing to
    // avoid a runtime crash if a non-String value ever lands on
    // 'Authorization' (interceptor would otherwise break the entire
    // request pipeline for one malformed header).
    final rawAuth = err.requestOptions.headers['Authorization'];
    final requestAuth = rawAuth is String ? rawAuth : null;
    final requestToken = (requestAuth != null && requestAuth.startsWith('Bearer '))
        ? requestAuth.substring('Bearer '.length)
        : null;
    if (currentToken != null && currentToken.isNotEmpty && requestToken != null && requestToken != currentToken) {
      _log.debug('JWT already rotated since {} was sent — retrying with current token', [requestPath]);
      await _retryWithToken(err, currentToken, handler);
      return;
    }

    final newIdToken = await _refreshOnce();
    if (newIdToken == null) {
      _triggerLogout();
      handler.next(err);
      return;
    }

    await _retryWithToken(err, newIdToken, handler);
  }

  /// Retry the original request with [token]. Forwards retry failures
  /// (not the original 401) to the handler so the real cause surfaces.
  ///
  /// Stamps [RequestOptions.extra] with [_retriedAfterRefresh] so a
  /// second 401 on the same retried request short-circuits to logout
  /// in [onError] — see the loop-prevention check there.
  Future<void> _retryWithToken(DioException err, String token, ErrorInterceptorHandler handler) async {
    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $token';
      retryOptions.extra[_retriedAfterRefresh] = true;
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      _log.error('Retry after refresh failed (Dio): {}', [retryErr.message]);
      handler.next(retryErr);
    } catch (e, st) {
      _log.error('Retry after refresh failed (non-Dio): {}', [e]);
      handler.next(
        DioException(requestOptions: err.requestOptions, error: e, stackTrace: st, type: DioExceptionType.unknown),
      );
    }
  }

  /// Returns a single in-flight refresh Future. The first caller starts
  /// the refresh; concurrent callers await the same Future. Cleared on
  /// completion so subsequent refresh windows start fresh.
  Future<String?> _refreshOnce() {
    return _inFlightRefresh ??= _performRefresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  /// Performs the actual refresh call + persistence. Returns the new
  /// idToken on success, null on any failure (missing refresh token,
  /// non-2xx response, malformed body, transport error).
  Future<String?> _performRefresh() async {
    try {
      final refreshToken = await _secureStorage.read(SecureStorageKeys.refreshToken.key);
      if (refreshToken == null || refreshToken.isEmpty) {
        _log.warn('No refresh token available — session expired');
        return null;
      }

      // Use a fresh Dio instance to bypass the interceptor chain.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post('/api/token/refresh', data: jsonEncode({'refresh_token': refreshToken}));

      if (response.statusCode != 200 && response.statusCode != 201) {
        _log.warn('Token refresh failed with status {} — session expired', [response.statusCode]);
        return null;
      }

      final data = response.data is String ? jsonDecode(response.data as String) : response.data;
      final newIdToken = data['id_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;

      if (newIdToken == null || newIdToken.isEmpty) {
        _log.error('Refresh response missing id_token — session expired');
        return null;
      }

      // Persist the rotated tokens. AuthInterceptor reads JWT from
      // secure storage on every request, so the next outgoing call
      // picks up the rotated value automatically.
      await _secureStorage.write(SecureStorageKeys.jwtToken.key, newIdToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _secureStorage.write(SecureStorageKeys.refreshToken.key, newRefreshToken);
      }

      _log.info('Token refresh successful');
      return newIdToken;
    } on DioException catch (e) {
      _log.error('Token refresh request failed: {}', [e.message]);
      return null;
    } catch (e) {
      _log.error('Unexpected error during token refresh: {}', [e]);
      return null;
    }
  }

  void _triggerLogout() {
    if (_onSessionExpired != null) {
      _log.info('Triggering session expired callback');
      _onSessionExpired();
    }
  }
}
