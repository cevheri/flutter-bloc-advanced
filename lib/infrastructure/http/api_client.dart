import 'dart:convert' show utf8;

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
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
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

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
///    just like a real round-trip (it resolves with callFollowing:true).
///
/// Error mapping happens in the convenience methods ([get], [post], etc.)
/// which catch [DioException] and rethrow as [AppException] types so that
/// repository catch blocks work without Dio coupling.
class ApiClient {
  static final _log = AppLogger.getLogger('ApiClient');

  static const int _timeoutSeconds = 30;

  static Dio? _dio;
  static Dio? _testDio;
  static List<InterceptorChainEntry> _interceptorChainSnapshot = const [];

  /// Snapshot of the active interceptor chain, in order. Populated the
  /// first time [instance] is read (i.e. when Dio is built).
  ///
  /// Consumers like `SystemDashboardCubit` should read this instead of
  /// hard-coding names — keeps the dashboard in sync with the chain
  /// even when interceptors are added, removed, or conditionally
  /// included (e.g. [MockInterceptor] outside production).
  static List<InterceptorChainEntry> get interceptorChainSnapshot => List.unmodifiable(_interceptorChainSnapshot);

  /// Callback invoked when the session has expired (token refresh failed).
  ///
  /// Set this before the first API call (typically in app initialization) so
  /// that the [TokenRefreshInterceptor] can notify the app layer to log out.
  static OnSessionExpired? onSessionExpired;

  /// Secure storage instance threaded into [AuthInterceptor] and
  /// [TokenRefreshInterceptor] when Dio is built. Bootstrap sets this
  /// to the same [ISecureStorage] adapter it uses for migration and
  /// the widget tree, so the HTTP interceptors and the repository
  /// layer share one source of truth. Falls back to a default
  /// [FlutterSecureStorageAdapter] when unset (tests that don't go
  /// through bootstrap).
  static ISecureStorage? secureStorage;

  /// Inject a custom Dio instance for testing.
  static void setTestInstance(Dio dio) => _testDio = dio;

  /// Reset the test instance.
  static void resetTestInstance() => _testDio = null;

  /// Reset the production singleton (useful in tests).
  ///
  /// Clears every static hook the class owns so a re-init path
  /// (hot reload, test tearDown, multi-test runs in one process)
  /// cannot leak a previous adapter/callback into the next Dio
  /// construction. Without resetting [secureStorage] / [onSessionExpired]
  /// here, a test that sets them and a later test that builds a fresh
  /// Dio would inherit those — silently re-binding the new interceptors
  /// to the previous run's instances.
  static void reset() {
    _dio?.close();
    _dio = null;
    _testDio = null;
    secureStorage = null;
    onSessionExpired = null;
  }

  /// The active Dio instance.
  static Dio get instance {
    if (_testDio != null) return _testDio!;
    return _dio ??= _createDio();
  }

  static Dio _createDio() {
    _log.debug('Creating Dio instance (production: {})', [ProfileConstants.isProduction]);
    if (secureStorage == null) {
      // Loud warning when Dio is built without a shared secureStorage.
      // Production code paths through AppBootstrap always set this
      // before the first HTTP call; if you see this in test or app
      // logs it means HTTP interceptors are about to construct their
      // own FlutterSecureStorageAdapter instance, which will diverge
      // from whatever the repository layer / SessionCubit are using.
      // Set ApiClient.secureStorage before touching ApiClient.instance
      // (test setup helpers do this — see test/test_utils.dart).
      _log.warn(
        'ApiClient.secureStorage is null at Dio creation — interceptors will fall back '
        'to a private FlutterSecureStorageAdapter and diverge from the repository layer.',
      );
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: ProfileConstants.isProduction ? (ProfileConstants.api as String) : '',
        connectTimeout: const Duration(seconds: _timeoutSeconds),
        receiveTimeout: const Duration(seconds: _timeoutSeconds),
        responseType: ResponseType.plain,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );

    // Certificate pinning. Empty pin list (default) keeps the system
    // adapter; populating ProfileConstants.certificatePins swaps in a
    // pinning adapter that fails closed on any non-matching cert. Web
    // is a hard no-op — see buildPinnedAdapter docs.
    final pins = ProfileConstants.certificatePins;
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
        interceptor: AuthInterceptor(secureStorage: secureStorage),
        meta: const InterceptorChainEntry(name: 'AuthInterceptor', detail: 'Attaches JWT token to requests'),
      ),
      (
        interceptor: TokenRefreshInterceptor(
          dio: dio,
          onSessionExpired: onSessionExpired,
          secureStorage: secureStorage,
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
        // Use the shared singleton so dashboard metrics (circuit breakers,
        // reset actions) target the same instance as real HTTP traffic
        // (fixes #60).
        interceptor: ResilienceInterceptor.instance,
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
      if (!ProfileConstants.isProduction)
        (
          interceptor: MockInterceptor(),
          meta: const InterceptorChainEntry(
            name: 'MockInterceptor',
            active: false,
            detail: 'Serves mock data in dev/test',
          ),
        ),
    ];

    dio.interceptors.addAll(chain.map((e) => e.interceptor));
    _interceptorChainSnapshot = chain.map((e) => e.meta).toList(growable: false);

    return dio;
  }

  // ---------------------------------------------------------------------------
  // Convenience methods matching the old HttpUtils API surface
  // ---------------------------------------------------------------------------

  static Future<Response<String>> get(String path, {String? pathParams, Map<String, dynamic>? queryParams}) async {
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

  static Future<Response<String>> post<T>(
    String path,
    T data, {
    Map<String, String>? headers,
    String? contentType,
    String? pathParams,
    bool idempotent = false,
  }) async {
    final fullPath = pathParams != null ? '$path/$pathParams' : path;
    final serialized = _serializeData(data);
    final options = Options(
      extra: {'_basePath': path, '_pathParams': pathParams, if (idempotent) IdempotencyInterceptor.optInExtraKey: true},
      headers: headers,
      contentType: contentType,
    );
    try {
      return await instance.post<String>(fullPath, data: serialized, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  static Future<Response<String>> put<T>(String path, T data, {String? pathParams, bool idempotent = false}) async {
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
          },
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  static Future<Response<String>> patch<T>(String path, T data, {String? pathParams, bool idempotent = false}) async {
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
          },
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  static Future<Response<String>> delete(String path, {String? pathParams, Map<String, dynamic>? queryParams}) async {
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

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return FetchDataException('TimeoutException');
      case DioExceptionType.connectionError:
        return FetchDataException('No Internet connection');
      case DioExceptionType.badResponse:
        return _mapBadResponse(e);
      case DioExceptionType.cancel:
        return FetchDataException('Request cancelled');
      case DioExceptionType.badCertificate:
        return FetchDataException('Bad certificate');
      case DioExceptionType.unknown:
        return _mapUnknown(e);
    }
  }

  static AppException _mapBadResponse(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    final body = e.response?.data?.toString() ?? '';
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
