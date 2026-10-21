import 'dart:convert' show utf8;

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinning_adapter.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/connectivity_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/cache_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/logging_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/dev_console_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/idempotency_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/mock_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/sensitive_keys.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/http/transport_errors.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/rotated_tokens_take_back.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';

/// Metadata describing one entry in the [ApiClient] interceptor chain.
///
/// Used by the system dashboard and other observers that want to render
/// the chain without hard-coding names/descriptions. Order matches the
/// order in which the interceptor was added to Dio.
class InterceptorChainEntry {
  const InterceptorChainEntry({required this.name, required this.detail, this.active = true});

  final String name;
  final String detail;
  final bool active;
}

/// Dio-based HTTP client with interceptor chain.
///
/// Interceptor order (single source of truth — see the chain below):
/// 1. [ConnectivityInterceptor] — rejects requests immediately when offline
/// 2. [AuthInterceptor] — injects JWT token
/// 3. [TokenRefreshInterceptor] — handles 401 responses with token refresh
/// 4. [IdempotencyInterceptor] — opt-in Idempotency-Key header for mutating
///    verbs (default off; retries reuse the same key)
/// 5. [ResilienceInterceptor] — smart retry + circuit breaker
/// 6. [CacheInterceptor] — GET response caching with TTL
/// 7. [DevConsoleInterceptor] — records requests in debug console
/// 8. [LoggingInterceptor] — structured request/response logging
/// 9. [MockInterceptor] — (dev/test only) simulates the network LAST, so its
///    response propagates back through the observability interceptors above
///    just like a real round-trip (it resolves with callFollowing:true). It
///    also answers the token refresh, which [TokenRefreshInterceptor] sends
///    through its own Dio.
///
/// Error mapping happens in the convenience methods ([get], [post], etc.)
/// which catch [DioException] and rethrow as [AppException] types so that
/// repository catch blocks work without Dio coupling.
///
/// [post], [put] and [patch] take `sensitiveKeys`, the keys of their data
/// whose values are secrets though their names hold no credential word. The
/// request carries them in its extra ([sensitiveKeysOf]), so the dev
/// console, the verbose log and the error text mask those values too.
///
/// `tokenRotation` replaces the backend's refresh endpoint ([BackendTokenRotation]) as the way
/// [TokenRefreshInterceptor] refreshes the session, and `isSessionExpired` decides which 401 starts
/// that refresh ([isUnauthorized], every 401, when it is null). On web the refresh takes turns at
/// `tokenRefreshLock` with the other browser tabs, and records what it stores in `rotatedTokensTakeBack`;
/// without them it runs at once and records nothing.
class ApiClient {
  ApiClient({
    required this._appConfig,
    this._secureStorage,
    this._onSessionExpired,
    this._dio,
    this._tokenRotation,
    this._isSessionExpired,
    this._tokenRefreshLock,
    this._rotatedTokensTakeBack,
  });

  static final _log = AppLogger.getLogger('ApiClient');

  static const int _timeoutSeconds = 30;

  /// How long a browser tab waits for its turn at the token refresh lock it shares with the other tabs
  /// ([ITokenRefreshLock]) before the request fails. It is longer than the longest turn that has a bound: a backend
  /// refresh, whose Dio takes this client's connect and receive timeouts ([defaultRefreshDio]), after a wait of at most
  /// [HandOverTokenRefreshLock.defaultCatchUpLimit] for the previous holder's writes, plus 10 seconds for the
  /// secure-storage writes and the hand-over. An `oidc` grant has no time limit of its own, so a grant that hangs keeps
  /// the other tabs waiting this long.
  static final tokenRefreshLockWaitLimit =
      const Duration(seconds: 2 * _timeoutSeconds) +
      HandOverTokenRefreshLock.defaultCatchUpLimit +
      const Duration(seconds: 10);

  final AppConfig _appConfig;
  final ISecureStorage? _secureStorage;
  final OnSessionExpired? _onSessionExpired;
  final TokenRotation? _tokenRotation;
  final SessionExpiredPredicate? _isSessionExpired;
  final ITokenRefreshLock? _tokenRefreshLock;
  final RotatedTokensTakeBack? _rotatedTokensTakeBack;
  Dio? _dio;
  List<InterceptorChainEntry> _chainSnapshot = const [];

  /// Snapshot of the active interceptor chain, in order. Populated the
  /// first time [instance] is read (i.e. when Dio is built).
  ///
  /// Consumers like `SystemDashboardCubit` should read this instead of
  /// hard-coding names — keeps the dashboard in sync with the chain
  /// even when interceptors are added, removed, or conditionally
  /// included (e.g. [MockInterceptor] outside production).
  List<InterceptorChainEntry> get interceptorChainSnapshot => List.unmodifiable(_chainSnapshot);

  /// The active Dio instance.
  Dio get instance => _dio ??= _createDio();

  Dio _createDio() {
    _log.debug('Creating Dio instance (production: {})', [_appConfig.isProduction]);
    if (_secureStorage == null) {
      // Loud warning when this ApiClient was built without an injected
      // secureStorage. Production wiring (AppDependencies.createApiClient)
      // always supplies the shared adapter; if you see this in test or app
      // logs it means the interceptors are about to construct their own
      // FlutterSecureStorageAdapter instance, which will diverge from
      // whatever the repository layer / SessionCubit are using.
      _log.warn(
        'ApiClient was constructed without a secureStorage — interceptors will fall back '
        'to a private FlutterSecureStorageAdapter and diverge from the repository layer.',
      );
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: _appConfig.apiBaseUrl ?? '',
        connectTimeout: const Duration(seconds: _timeoutSeconds),
        receiveTimeout: const Duration(seconds: _timeoutSeconds),
        responseType: ResponseType.plain,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );

    // Certificate pinning. Empty pin list (default) keeps the system
    // adapter; populating appConfig.certificatePins swaps in a
    // pinning adapter that fails closed on any non-matching cert. Web
    // is a hard no-op — see buildPinnedAdapter docs.
    // Retries and the token refresh are sent through this same adapter
    // (ResilienceInterceptor.forDio, TokenRefreshInterceptor), so the
    // pins cover every request the client sends.
    final pins = _appConfig.certificatePins;
    if (pins.isNotEmpty) {
      _log.info('Installing certificate pinning adapter ({} pin(s))', [pins.length]);
      dio.httpClientAdapter = buildPinnedAdapter(pins);
    }

    // Single source of truth for the chain: each entry pairs the live
    // [Interceptor] with the human-readable metadata that the dashboard
    // shows. Adding/removing an interceptor here automatically updates
    // [interceptorChainSnapshot] — no separate hardcoded list to drift.
    final chain = <({Interceptor interceptor, InterceptorChainEntry meta})>[
      (
        interceptor: ConnectivityInterceptor(),
        meta: const InterceptorChainEntry(name: 'ConnectivityInterceptor', detail: 'Rejects requests when offline'),
      ),
      (
        interceptor: AuthInterceptor(secureStorage: _secureStorage),
        meta: const InterceptorChainEntry(name: 'AuthInterceptor', detail: 'Attaches JWT token to requests'),
      ),
      (
        interceptor: TokenRefreshInterceptor(
          dio: dio,
          onSessionExpired: _onSessionExpired,
          secureStorage: _secureStorage,
          refreshDioFactory: _appConfig.isProduction ? null : _mockRefreshDio,
          rotation: _tokenRotation,
          isSessionExpired: _isSessionExpired ?? isUnauthorized,
          refreshLock: _tokenRefreshLock,
          takeBack: _rotatedTokensTakeBack,
        ),
        meta: const InterceptorChainEntry(name: 'TokenRefreshInterceptor', detail: 'Refreshes expired access tokens'),
      ),
      (
        // Idempotency runs before Resilience so the key is set on the very
        // first outbound request and is then naturally reused on every
        // retry pass (Resilience and TokenRefresh both re-fetch the same
        // RequestOptions instance, which carries the cached key in extra).
        interceptor: IdempotencyInterceptor(),
        meta: const InterceptorChainEntry(
          name: 'IdempotencyInterceptor',
          active: false,
          detail: 'Opt-in Idempotency-Key for POST/PUT/PATCH',
        ),
      ),
      (
        // Share the singleton's circuit breakers so dashboard metrics
        // and reset actions see real HTTP traffic (fixes #60). forDio
        // sends retries through this Dio's adapter, pins included.
        interceptor: ResilienceInterceptor.instance.forDio(dio),
        meta: const InterceptorChainEntry(name: 'ResilienceInterceptor', detail: 'Retry + circuit breaker'),
      ),
      (
        interceptor: CacheInterceptor(),
        meta: const InterceptorChainEntry(name: 'CacheInterceptor', detail: 'GET response caching with TTL'),
      ),
      (
        interceptor: DevConsoleInterceptor(),
        meta: const InterceptorChainEntry(name: 'DevConsoleInterceptor', detail: 'Records requests in dev console'),
      ),
      (
        interceptor: LoggingInterceptor(),
        meta: const InterceptorChainEntry(name: 'LoggingInterceptor', detail: 'Structured request/response logging'),
      ),
      // Mock sits LAST: it simulates the server, so its resolved response
      // must travel back up through the observability interceptors above
      // (DevConsole capture + verbose logging). It resolves with
      // callFollowing:true to make that happen.
      if (!_appConfig.isProduction)
        (
          interceptor: MockInterceptor(appConfig: _appConfig),
          meta: const InterceptorChainEntry(
            name: 'MockInterceptor',
            active: false,
            detail: 'Serves mock data in dev/test',
          ),
        ),
    ];

    dio.interceptors.addAll(chain.map((e) => e.interceptor));
    _chainSnapshot = chain.map((e) => e.meta).toList(growable: false);

    return dio;
  }

  /// The refresh Dio outside production. [TokenRefreshInterceptor] sends the
  /// token refresh through its own Dio, which skips the chain above and so
  /// the [MockInterceptor] at its end. That Dio gets a [MockInterceptor] of
  /// its own, so the mock answers the refresh as the server would instead of
  /// the request going to the network.
  Dio _mockRefreshDio(Dio source) =>
      TokenRefreshInterceptor.defaultRefreshDio(source)..interceptors.add(MockInterceptor(appConfig: _appConfig));

  // ---------------------------------------------------------------------------
  // Convenience methods matching the old HttpUtils API surface
  // ---------------------------------------------------------------------------

  Future<Response<String>> get(String path, {String? pathParams, Map<String, dynamic>? queryParams}) async {
    final fullPath = pathParams != null ? '$path/$pathParams' : path;
    try {
      return await instance.get<String>(
        fullPath,
        queryParameters: queryParams,
        options: Options(extra: {'_basePath': path, '_pathParams': pathParams, '_queryParams': queryParams}),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<String>> post<T>(
    String path,
    T data, {
    Map<String, String>? headers,
    String? contentType,
    String? pathParams,
    bool idempotent = false,
    Set<String> sensitiveKeys = const {},
  }) async {
    final fullPath = pathParams != null ? '$path/$pathParams' : path;
    final serialized = _serializeData(data);
    final options = Options(
      extra: {
        '_basePath': path,
        '_pathParams': pathParams,
        if (idempotent) IdempotencyInterceptor.optInExtraKey: true,
        if (sensitiveKeys.isNotEmpty) sensitiveKeysExtra: sensitiveKeys,
      },
      headers: headers,
      contentType: contentType,
    );
    try {
      return await instance.post<String>(fullPath, data: serialized, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<String>> put<T>(
    String path,
    T data, {
    String? pathParams,
    bool idempotent = false,
    Set<String> sensitiveKeys = const {},
  }) async {
    final fullPath = pathParams != null ? '$path/$pathParams' : path;
    final serialized = _serializeData(data);
    try {
      return await instance.put<String>(
        fullPath,
        data: serialized,
        options: Options(
          extra: {
            '_basePath': path,
            '_pathParams': pathParams,
            if (idempotent) IdempotencyInterceptor.optInExtraKey: true,
            if (sensitiveKeys.isNotEmpty) sensitiveKeysExtra: sensitiveKeys,
          },
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<String>> patch<T>(
    String path,
    T data, {
    String? pathParams,
    bool idempotent = false,
    Set<String> sensitiveKeys = const {},
  }) async {
    final fullPath = pathParams != null ? '$path/$pathParams' : path;
    final serialized = _serializeData(data);
    try {
      return await instance.patch<String>(
        fullPath,
        data: serialized,
        options: Options(
          extra: {
            '_basePath': path,
            '_pathParams': pathParams,
            if (idempotent) IdempotencyInterceptor.optInExtraKey: true,
            if (sensitiveKeys.isNotEmpty) sensitiveKeysExtra: sensitiveKeys,
          },
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<String>> delete(String path, {String? pathParams, Map<String, dynamic>? queryParams}) async {
    final fullPath = pathParams != null ? '$path/$pathParams' : path;
    try {
      return await instance.delete<String>(
        fullPath,
        queryParameters: queryParams,
        options: Options(extra: {'_basePath': path, '_pathParams': pathParams, '_queryParams': queryParams}),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Error mapping — converts DioException to AppException hierarchy
  // ---------------------------------------------------------------------------

  static AppException _mapDioException(DioException e) {
    // If the wrapped error is already an AppException (e.g. from MockInterceptor),
    // unwrap and rethrow it directly.
    if (e.error is AppException) return e.error as AppException;
    // A TLS failure gets its own type, so repositories can report AppErrorCode.networkCertInvalid instead of a
    // generic communication error: a pin mismatch, or a certificate the device does not trust. dio reports both as
    // unknown, with the exception as its error. On web the browser reports them as connection errors.
    if (isTlsError(e.error)) return _untrustedCertificate(e);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return FetchDataException('TimeoutException');
      case DioExceptionType.connectionError:
        return FetchDataException('No Internet connection');
      case DioExceptionType.badResponse:
        return _mapBadResponse(e);
      case DioExceptionType.cancel:
        return FetchDataException('Request cancelled');
      case DioExceptionType.badCertificate:
        return _untrustedCertificate(e);
      case DioExceptionType.unknown:
        return _mapUnknown(e);
    }
  }

  /// An [UntrustedCertificateException] for the TLS failure [e]. Its message is for the log, never for the user: it
  /// names the host and port and keeps what dart:io or dio reported, such as the OS error of a failed handshake.
  static UntrustedCertificateException _untrustedCertificate(DioException e) {
    final error = e.error;
    // Its message names the host and port already, so the log line of a pin mismatch stays as it was.
    if (error is CertificatePinningException) return UntrustedCertificateException(error.toString());
    final uri = e.requestOptions.uri;
    return UntrustedCertificateException('Untrusted connection to ${uri.host}:${uri.port}: ${e.message ?? error}');
  }

  static AppException _mapBadResponse(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    // The body becomes the text of the exception, which the log, the dev console and Sentry receive, and a validation
    // error can repeat the password or the code the request sent.
    final body = scrubErrorBody(
      e.response?.data,
      requestBody: e.requestOptions.data,
      sensitiveKeys: sensitiveKeysOf(e.requestOptions),
    );
    switch (statusCode) {
      case 400:
        return BadRequestException(body);
      case 401:
        return UnauthorizedException(body);
      case 403:
        return UnauthorizedException(body);
      case 404:
        return FetchDataException('Not found: $body');
      case >= 500:
        return FetchDataException('Server error ($statusCode): $body');
      default:
        return FetchDataException('HTTP $statusCode: $body');
    }
  }

  static AppException _mapUnknown(DioException e) {
    final message = e.error?.toString() ?? e.message ?? 'Unknown error';
    if (message.contains('SocketException')) return FetchDataException('No Internet connection');
    if (message.contains('Timeout') || message.contains('timeout')) return FetchDataException('TimeoutException');
    return FetchDataException(message);
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  /// Decode a potentially malformed UTF-8 string.
  static String decodeUTF8(String toEncode) {
    try {
      List<int> codePoints = toEncode.runes.toList();
      List<int> utf8Bytes = utf8.encode(String.fromCharCodes(codePoints));
      return utf8.decode(utf8Bytes, allowMalformed: true);
    } catch (e) {
      return toEncode;
    }
  }

  /// Serialize [data] for Dio: Maps/Strings/Lists pass through; objects call `toJson()`.
  static dynamic _serializeData<T>(T data) {
    if (data is Map || data is String || data is List) return data;
    return (data as dynamic).toJson();
  }
}
