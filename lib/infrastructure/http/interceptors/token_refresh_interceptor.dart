import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// Backend contract for the refresh endpoint, isolated as named
/// constants so a typo or rename surfaces at one site instead of
/// scattering across the file. Not exported (private to this library)
/// because they describe how *this* interceptor talks to the backend —
/// not a project-wide HTTP policy.
class _RefreshEndpoint {
  static const path = '/api/token/refresh';
  static const requestKeyRefreshToken = 'refresh_token';
  static const responseKeyIdToken = 'id_token';
  static const responseKeyRefreshToken = 'refresh_token';
}

/// HTTP auth header shape. Same locality reasoning as
/// [_RefreshEndpoint] — these are how this layer writes the header,
/// not a cross-feature contract.
class _AuthHeader {
  static const name = 'Authorization';
  static const bearerPrefix = 'Bearer ';
}

/// Callback signature for notifying the app layer that the session has expired
/// and the user must be logged out.
///
/// By using a callback we avoid importing anything from `app/` in the
/// infrastructure layer.
typedef OnSessionExpired = void Function();

/// Factory for the bare [Dio] instance used to POST the refresh
/// request. A separate Dio is needed so the refresh call bypasses the
/// production interceptor chain (otherwise a 401 on `/api/token/refresh`
/// would re-enter this interceptor recursively). Pluggable so tests
/// can short-circuit the POST without depending on `http_mock_adapter`.
typedef RefreshDioFactory = Dio Function(Dio sourceDio);

/// Intercepts 401 responses and attempts a silent token refresh.
///
/// Extends [QueuedInterceptor] so dio queues concurrent 401s, but the
/// refresh request itself is also coalesced via a shared in-flight
/// [Future]. When several requests fail with 401 around the same time
/// the first one starts the refresh; the rest await the same Future
/// and retry with the already-rotated token instead of triggering a
/// refresh storm against the refresh endpoint.
///
/// Must be registered after [AuthInterceptor] in the chain — see
/// `ApiClient._createDio` for the single source of truth on order
/// (any inline ASCII diagram here would drift the next time the
/// chain is edited).
class TokenRefreshInterceptor extends QueuedInterceptor {
  static final _log = AppLogger.getLogger('TokenRefreshInterceptor');

  final Dio _dio;
  final OnSessionExpired? _onSessionExpired;
  final ISecureStorage _secureStorage;
  final RefreshDioFactory _refreshDioFactory;

  /// Shared in-flight refresh. Non-null while a refresh is in progress;
  /// concurrent 401s await the same Future. Cleared on completion (success
  /// or failure) so the next refresh window can start a fresh attempt.
  Future<String?>? _inFlightRefresh;

  TokenRefreshInterceptor({
    required Dio dio,
    OnSessionExpired? onSessionExpired,
    ISecureStorage? secureStorage,
    RefreshDioFactory? refreshDioFactory,
  }) : _dio = dio,
       _onSessionExpired = onSessionExpired,
       _secureStorage = secureStorage ?? FlutterSecureStorageAdapter(),
       _refreshDioFactory = refreshDioFactory ?? _defaultRefreshDio;

  static Dio _defaultRefreshDio(Dio source) => Dio(
    BaseOptions(
      baseUrl: source.options.baseUrl,
      connectTimeout: source.options.connectTimeout,
      receiveTimeout: source.options.receiveTimeout,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ),
  );

  /// Typed marker that flags a [RequestOptions] as "already retried
  /// once after a successful refresh." A second 401 on the same
  /// request short-circuits to logout instead of attempting another
  /// refresh — prevents infinite refresh loops when the backend keeps
  /// rejecting freshly-rotated tokens (revoked session, clock skew,
  /// backend bug, etc.).
  ///
  /// Uses [Expando] keyed on the [RequestOptions] instance instead of
  /// the prior stringly-typed `extra['_tokenRefresh_retried']`. The
  /// previous shape was vulnerable to map-key collisions and `== true`
  /// comparison drift (would silently fail for `'true'` or `1`).
  /// The Expando is per-instance, so the marker cannot leak to
  /// unrelated requests.
  static final _retriedAfterRefresh = Expando<bool>('_tokenRefresh_retried');

  /// Test-only helpers around the private retry marker. Production
  /// code never calls these — the marker is stamped exclusively by
  /// [_retryWithToken] after a successful refresh round, and read
  /// exclusively by [onError]'s loop-prevention check. Exposed via
  /// `@visibleForTesting` so tests can drive the loop-prevention
  /// branch directly and assert that the retry path stamps the
  /// marker, without leaking the [Expando] mechanism into production
  /// callers.
  @visibleForTesting
  static void debugMarkAsRetried(RequestOptions options) {
    _retriedAfterRefresh[options] = true;
  }

  @visibleForTesting
  static bool debugIsMarkedAsRetried(RequestOptions options) {
    return _retriedAfterRefresh[options] == true;
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 Unauthorized responses
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Avoid refreshing on the refresh endpoint itself to prevent infinite loops
    final requestPath = err.requestOptions.path;
    if (requestPath.contains(_RefreshEndpoint.path)) {
      _log.warn('Refresh endpoint returned 401 — session expired');
      _triggerLogout();
      handler.next(err);
      return;
    }

    // Second 401 on the same request after a refresh+retry round
    // already happened — refusing to refresh again. The newly-rotated
    // token is being rejected; another refresh would just produce
    // another rejected token. Surface the failure and log out.
    if (_retriedAfterRefresh[err.requestOptions] == true) {
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
    // [_AuthHeader.name] (interceptor would otherwise break the entire
    // request pipeline for one malformed header).
    final rawAuth = err.requestOptions.headers[_AuthHeader.name];
    final requestAuth = rawAuth is String ? rawAuth : null;
    final requestToken = (requestAuth != null && requestAuth.startsWith(_AuthHeader.bearerPrefix))
        ? requestAuth.substring(_AuthHeader.bearerPrefix.length)
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
      retryOptions.headers[_AuthHeader.name] = '${_AuthHeader.bearerPrefix}$token';
      _retriedAfterRefresh[retryOptions] = true;
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
      final refreshDio = _refreshDioFactory(_dio);

      final response = await refreshDio.post(
        _RefreshEndpoint.path,
        data: jsonEncode({_RefreshEndpoint.requestKeyRefreshToken: refreshToken}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        _log.warn('Token refresh failed with status {} — session expired', [response.statusCode]);
        return null;
      }

      final data = response.data is String ? jsonDecode(response.data as String) : response.data;
      final newIdToken = data[_RefreshEndpoint.responseKeyIdToken] as String?;
      final newRefreshToken = data[_RefreshEndpoint.responseKeyRefreshToken] as String?;

      if (newIdToken == null || newIdToken.isEmpty) {
        _log.error('Refresh response missing id_token — session expired');
        return null;
      }

      // Persist the rotated tokens. AuthInterceptor reads JWT from
      // secure storage on every request, so the next outgoing call
      // picks up the rotated value automatically.
      //
      // Both writes are wrapped together with rollback-to-prior so a
      // partial failure (id_token persisted, refresh_token throws)
      // cannot leave a torn pair on disk. A torn pair would let the
      // next request succeed briefly with the new id_token, then fail
      // on the following 401 because the refresh_token is stale — a
      // user-visible logout for a reason unrelated to the original
      // failure. Snapshotting prior values mirrors the pattern in
      // AuthSessionRepositoryImpl.persist.
      String? priorIdToken;
      try {
        priorIdToken = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
      } catch (e) {
        // Snapshot read failed; rollback for jwtToken will fall
        // through to delete. The session-expired callback will then
        // force a clean re-auth.
        _log.warn('Failed to snapshot prior id_token before persist: {}', [e]);
      }

      try {
        await _secureStorage.write(SecureStorageKeys.jwtToken.key, newIdToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _secureStorage.write(SecureStorageKeys.refreshToken.key, newRefreshToken);
        }
      } catch (e, st) {
        _log.error('Persist of rotated tokens failed — rolling back to prior values: {}', [e, st]);
        await _restoreOrDelete(SecureStorageKeys.jwtToken, priorIdToken);
        await _restoreOrDelete(SecureStorageKeys.refreshToken, refreshToken);
        return null;
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

  /// Best-effort rollback helper for [_performRefresh]: writes [prior]
  /// back if it was present, otherwise deletes the key. Swallows any
  /// failure so a rollback never escalates beyond a clean
  /// session-expired callback for the user.
  Future<void> _restoreOrDelete(SecureStorageKeys key, String? prior) async {
    try {
      if (prior != null && prior.isNotEmpty) {
        await _secureStorage.write(key.key, prior);
      } else {
        await _secureStorage.delete(key.key);
      }
    } catch (e) {
      _log.warn('Rollback failed for {}: {}', [key.key, e]);
    }
  }

  void _triggerLogout() {
    if (_onSessionExpired != null) {
      _log.info('Triggering session expired callback');
      _onSessionExpired();
    }
  }
}
