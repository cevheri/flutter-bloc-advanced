import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/dev_console_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/transport_errors.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';

/// Dio interceptor that caches successful GET responses and serves them
/// when offline or when a [CachePolicy] is specified.
///
/// Cache behavior is controlled via `options.extra['cachePolicy']`.
/// Only GET requests are cached. POST/PUT/DELETE skip caching.
///
/// A response is not stored when the session it was sent under has ended
/// since, or is being wiped: a logout or the end of the session clears the
/// cache, and the response of a GET still on its way then would answer the
/// next user with the data of the user who signed out. The session is the
/// [SessionGeneration] that `AuthInterceptor` records before it reads the
/// token; a request to a public endpoint has none and belongs to no session.
///
/// A cacheOnly GET with nothing cached fails with "No cached data available",
/// rejected with `callFollowingErrorInterceptor: true` so that the dev
/// console and the HTTP log record it like any other failure.
///
/// When a GET cannot reach the server, the networkFirst and cacheFirst
/// policies answer it from the cache with an `x-cache: stale` header: after
/// a connection error, a timeout, or a connection closed or reset before the
/// whole response arrived. That includes a GET sent while the device is
/// offline: `ConnectivityInterceptor` rejects it as a connection error that
/// still reaches [onError]. A fresh cacheFirst entry answers it with
/// `x-cache: hit`, as it would before the network.
///
/// A response that dart:io cannot parse is answered the same way: dart:io
/// reports it as an `HttpException`, like a connection reset while the
/// response is awaited. Every other error propagates. A TLS failure (an
/// untrusted, expired or self-signed certificate, a hostname mismatch, a
/// certificate pin mismatch, a handshake closed before it completed) means
/// the connection may be intercepted, so it fails instead of showing earlier
/// data. A handshake reset before it completed is a connection error, so it
/// is answered. On web the browser reports a TLS failure as a connection
/// error, which cannot be told apart from a lost connection.
///
/// An entry is fresh for its TTL, 5 minutes unless `options.extra['cacheTtl']`
/// sets another: cacheFirst and cacheOnly answer from a fresh entry only.
/// Past its TTL it still answers a GET that cannot reach the server until it
/// is [CacheEntry.maxStaleAge] (24 hours) old. The storage deletes it when it
/// reads it after that, and every entry when the session ends.
class CacheInterceptor extends Interceptor {
  CacheInterceptor({ICacheStorage? storage}) : _storage = storage ?? SharedPrefsCacheStorage();

  static final _log = AppLogger.getLogger('CacheInterceptor');

  final ICacheStorage _storage;
  static const Duration _defaultTtl = Duration(minutes: 5);

  /// Whether [options] is a GET that this interceptor answers from the cache alone ([CachePolicy.cacheOnly]).
  ///
  /// Such a request never reaches the network, so no network check applies to it: `ConnectivityInterceptor` lets it
  /// through while the device is offline, and `ResilienceInterceptor` while the circuit of its endpoint is open.
  static bool isCacheOnly(RequestOptions options) =>
      options.method.toUpperCase() == 'GET' && _extractPolicy(options) == CachePolicy.cacheOnly;

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
      if (entry != null && entry.isValid) {
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
      // Runs every onError handler, so the dev console and the HTTP log record the failure like any other.
      handler.reject(
        DioException(requestOptions: options, type: DioExceptionType.unknown, message: 'No cached data available'),
        true,
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
        // Checked right before the write, so a wipe that started while the response was on its way counts.
        if (_sessionHasEnded(response.requestOptions)) {
          _log.info('Not caching GET {}: its session ended while it was on its way', [response.requestOptions.path]);
        } else {
          await _storage.write(key, response.data.toString(), ttl: ttl);
        }
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only a GET that could not reach the server falls back to the cache. Everything else propagates: a server
    // answer (401, 403, 5xx), a TLS failure and an unexpected error.
    if (err.requestOptions.method.toUpperCase() == 'GET' && _couldNotReachServer(err)) {
      final policy = _extractPolicy(err.requestOptions);
      if (policy == CachePolicy.networkFirst || policy == CachePolicy.cacheFirst) {
        final entry = await _storage.read(_cacheKey(err.requestOptions));
        if (entry != null) {
          // A fresh cacheFirst entry is the answer onRequest gives before the network, so it is a hit: it gets here
          // when ConnectivityInterceptor rejected the GET before this interceptor saw it. Any other entry stands in
          // for the server that could not be reached.
          final cacheStatus = policy == CachePolicy.cacheFirst && entry.isValid ? 'hit' : 'stale';
          _log.info('Answering GET {} from the cache ({}) after {}', [
            err.requestOptions.path,
            cacheStatus,
            err.type.name,
          ]);
          final response = Response(
            requestOptions: err.requestOptions,
            statusCode: 200,
            data: entry.data,
            headers: Headers.fromMap({
              'x-cache': [cacheStatus],
            }),
          );
          // Resolving here ends the error chain before DevConsoleInterceptor, which sits after this interceptor,
          // so the entry it added for a GET that went out would stay in flight.
          DevConsoleInterceptor.recordAnswer(err, response);
          handler.resolve(response);
          return;
        }
      }
    }
    handler.next(err);
  }

  /// Whether [err] means the GET could not reach the server, the only failure the cache answers.
  ///
  /// An allowlist: a connection error, a timeout, and an unknown error with the dart:io error of a connection closed
  /// or reset before the whole response arrived, or of a response dart:io could not parse ([isLostConnection]).
  /// Anything else propagates, every TLS failure included: dio reports one as unknown with a dart:io `TlsException`,
  /// such as the `HandshakeException` of an untrusted, expired or self-signed certificate, a wrong device clock, a
  /// hostname mismatch, a captive portal, an intercepting proxy or a handshake closed before it completed, or with a
  /// `CertificatePinningException`. A handshake reset before it completed is a connection error, so it is answered.
  ///
  /// On web the browser reports a TLS failure as a connection error without saying why the connection failed, so
  /// there it cannot be told apart from a lost connection and is answered from the cache.
  bool _couldNotReachServer(DioException err) => switch (err.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    DioExceptionType.unknown => isLostConnection(err.error),
    DioExceptionType.badResponse ||
    DioExceptionType.badCertificate ||
    DioExceptionType.cancel ||
    DioExceptionType.transformTimeout => false,
  };

  /// Whether the session that [options] was sent under has ended or is being wiped. A request without a recorded
  /// session, such as one to a public endpoint, carries no user's data.
  static bool _sessionHasEnded(RequestOptions options) {
    final sentUnder = AuthInterceptor.sessionGenerationOf(options);
    return sentUnder != null && SessionGeneration.hasEnded(sentUnder);
  }

  static CachePolicy _extractPolicy(RequestOptions options) {
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
