import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';

/// Dio interceptor that caches successful GET responses and serves them
/// when offline or when a [CachePolicy] is specified.
///
/// Cache behavior is controlled via `options.extra['cachePolicy']`.
/// Only GET requests are cached. POST/PUT/DELETE skip caching.
///
/// Default cache TTL: 5 minutes.
class CacheInterceptor extends Interceptor {
  CacheInterceptor({ICacheStorage? storage}) : _storage = storage ?? SharedPrefsCacheStorage();

  static final _log = AppLogger.getLogger('CacheInterceptor');

  final ICacheStorage _storage;
  static const Duration _defaultTtl = Duration(minutes: 5);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      handler.next(options);
      return;
    }

    final policy = _extractPolicy(options);

    // CacheOnly: serve from cache, skip network
    if (policy == CachePolicy.cacheOnly) {
      final entry = await _storage.read(_cacheKey(options));
      if (entry != null) {
        _log.debug('Cache hit (cacheOnly): {}', [options.path]);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: entry.data,
            headers: Headers.fromMap({
              'x-cache': ['hit'],
            }),
          ),
        );
        return;
      }
      handler.reject(
        DioException(requestOptions: options, type: DioExceptionType.unknown, message: 'No cached data available'),
      );
      return;
    }

    // CacheFirst: try cache, then network
    if (policy == CachePolicy.cacheFirst) {
      final entry = await _storage.read(_cacheKey(options));
      if (entry != null && entry.isValid) {
        _log.debug('Cache hit (cacheFirst): {}', [options.path]);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: entry.data,
            headers: Headers.fromMap({
              'x-cache': ['hit'],
            }),
          ),
        );
        return;
      }
    }

    // NetworkFirst or NetworkOnly: proceed to network
    handler.next(options);
  }

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Cache successful GET responses
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode != null &&
        response.statusCode! < 300 &&
        response.data != null) {
      final policy = _extractPolicy(response.requestOptions);
      if (policy != CachePolicy.networkOnly) {
        final key = _cacheKey(response.requestOptions);
        final ttl = _extractTtl(response.requestOptions);
        await _storage.write(key, response.data.toString(), ttl: ttl);
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // On network error for GET requests with networkFirst policy: try cache fallback
    if (err.requestOptions.method.toUpperCase() == 'GET') {
      final policy = _extractPolicy(err.requestOptions);
      if (policy == CachePolicy.networkFirst || policy == CachePolicy.cacheFirst) {
        final entry = await _storage.read(_cacheKey(err.requestOptions));
        if (entry != null) {
          _log.info('Serving stale cache for offline request: {}', [err.requestOptions.path]);
          handler.resolve(
            Response(
              requestOptions: err.requestOptions,
              statusCode: 200,
              data: entry.data,
              headers: Headers.fromMap({
                'x-cache': ['stale'],
              }),
            ),
          );
          return;
        }
      }
    }
    handler.next(err);
  }

  CachePolicy _extractPolicy(RequestOptions options) {
    final extra = options.extra['cachePolicy'];
    if (extra is CachePolicy) return extra;
    return CachePolicy.networkFirst; // Default
  }

  Duration _extractTtl(RequestOptions options) {
    final extra = options.extra['cacheTtl'];
    if (extra is Duration) return extra;
    return _defaultTtl;
  }

  String _cacheKey(RequestOptions options) {
    return '${options.method}_${options.uri}';
  }
}
