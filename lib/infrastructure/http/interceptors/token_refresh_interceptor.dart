import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

/// Callback signature for notifying the app layer that the session has expired
/// and the user must be logged out.
///
/// By using a callback we avoid importing anything from `app/` in the
/// infrastructure layer.
typedef OnSessionExpired = void Function();

/// Intercepts 401 responses and attempts a silent token refresh.
///
/// Extends [QueuedInterceptor] so that concurrent requests hitting a 401 are
/// serialised — only one refresh attempt is made and all queued requests are
/// retried with the new token.
///
/// Interceptor order (must come AFTER [AuthInterceptor]):
/// ```
/// AuthInterceptor -> TokenRefreshInterceptor -> MockInterceptor? -> ...
/// ```
class TokenRefreshInterceptor extends QueuedInterceptor {
  static final _log = AppLogger.getLogger('TokenRefreshInterceptor');

  final Dio _dio;
  final OnSessionExpired? _onSessionExpired;

  TokenRefreshInterceptor({required Dio dio, OnSessionExpired? onSessionExpired})
    : _dio = dio,
      _onSessionExpired = onSessionExpired;

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

    _log.debug('401 received for {} — attempting token refresh', [requestPath]);

    try {
      final refreshToken = await AppLocalStorage().read(StorageKeys.refreshToken.name);
      if (refreshToken == null || (refreshToken is String && refreshToken.isEmpty)) {
        _log.warn('No refresh token available — session expired');
        _triggerLogout();
        handler.next(err);
        return;
      }

      // Attempt token refresh using a fresh Dio instance to bypass interceptors
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post('/api/token/refresh', data: jsonEncode({'refresh_token': refreshToken}));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is String ? jsonDecode(response.data as String) : response.data;

        final newIdToken = data['id_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newIdToken == null || newIdToken.isEmpty) {
          _log.error('Refresh response missing id_token — session expired');
          _triggerLogout();
          handler.next(err);
          return;
        }

        // Persist the new tokens
        await AppLocalStorage().save(StorageKeys.jwtToken.name, newIdToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await AppLocalStorage().save(StorageKeys.refreshToken.name, newRefreshToken);
        }

        _log.info('Token refresh successful — retrying original request');

        // Retry the original request with the new token
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newIdToken';

        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
        return;
      } else {
        _log.warn('Token refresh failed with status {} — session expired', [response.statusCode]);
        _triggerLogout();
        handler.next(err);
        return;
      }
    } on DioException catch (e) {
      _log.error('Token refresh request failed: {}', [e.message]);
      _triggerLogout();
      handler.next(err);
    } catch (e) {
      _log.error('Unexpected error during token refresh: {}', [e]);
      _triggerLogout();
      handler.next(err);
    }
  }

  void _triggerLogout() {
    if (_onSessionExpired != null) {
      _log.info('Triggering session expired callback');
      _onSessionExpired();
    }
  }
}
