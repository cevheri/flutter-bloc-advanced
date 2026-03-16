import 'dart:convert' show utf8;

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/connectivity_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/cache_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/logging_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/dev_console_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/mock_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';

/// Dio-based HTTP client with interceptor chain.
///
/// Interceptor order:
/// 1. [ConnectivityInterceptor] — rejects requests immediately when offline
/// 2. [AuthInterceptor] — injects JWT token
/// 3. [TokenRefreshInterceptor] — handles 401 responses with token refresh
/// 4. [ResilienceInterceptor] — smart retry + circuit breaker
/// 5. [MockInterceptor] — (dev/test only) short-circuits with mock data
/// 6. [DevConsoleInterceptor] — records requests in debug console
/// 7. [LoggingInterceptor] — structured request/response logging
///
/// Error mapping happens in the convenience methods ([get], [post], etc.)
/// which catch [DioException] and rethrow as [AppException] types so that
/// repository catch blocks work without Dio coupling.
class ApiClient {
  static final _log = AppLogger.getLogger('ApiClient');

  static const int _timeoutSeconds = 30;

  static Dio? _dio;
  static Dio? _testDio;

  /// Callback invoked when the session has expired (token refresh failed).
  ///
  /// Set this before the first API call (typically in app initialization) so
  /// that the [TokenRefreshInterceptor] can notify the app layer to log out.
  static OnSessionExpired? onSessionExpired;

  /// Inject a custom Dio instance for testing.
  static void setTestInstance(Dio dio) => _testDio = dio;

  /// Reset the test instance.
  static void resetTestInstance() => _testDio = null;

  /// Reset the production singleton (useful in tests).
  static void reset() {
    _dio?.close();
    _dio = null;
    _testDio = null;
  }

  /// The active Dio instance.
  static Dio get instance {
    if (_testDio != null) return _testDio!;
    return _dio ??= _createDio();
  }

  static Dio _createDio() {
    _log.debug('Creating Dio instance (production: {})', [ProfileConstants.isProduction]);

    final dio = Dio(
      BaseOptions(
        baseUrl: ProfileConstants.isProduction ? (ProfileConstants.api as String) : '',
        connectTimeout: const Duration(seconds: _timeoutSeconds),
        receiveTimeout: const Duration(seconds: _timeoutSeconds),
        responseType: ResponseType.plain,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      ConnectivityInterceptor(),
      AuthInterceptor(),
      TokenRefreshInterceptor(dio: dio, onSessionExpired: onSessionExpired),
      ResilienceInterceptor(),
      if (!ProfileConstants.isProduction) MockInterceptor(),
      CacheInterceptor(),
      DevConsoleInterceptor(),
      LoggingInterceptor(),
    ]);

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
  }) async {
    final serialized = _serializeData(data);
    final options = Options(extra: {'_basePath': path}, headers: headers, contentType: contentType);
    try {
      return await instance.post<String>(path, data: serialized, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  static Future<Response<String>> put<T>(String path, T data) async {
    final serialized = _serializeData(data);
    try {
      return await instance.put<String>(
        path,
        data: serialized,
        options: Options(extra: {'_basePath': path}),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  static Future<Response<String>> patch<T>(String path, T data) async {
    final serialized = _serializeData(data);
    try {
      return await instance.patch<String>(
        path,
        data: serialized,
        options: Options(extra: {'_basePath': path}),
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
