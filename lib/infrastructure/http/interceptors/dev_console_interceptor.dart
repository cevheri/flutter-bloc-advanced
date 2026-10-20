import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/infrastructure/http/sensitive_keys.dart';

/// Dio interceptor that records HTTP requests/responses to [DevConsoleStore].
///
/// Only active in debug mode — production builds skip entirely.
///
/// Headers and bodies are recorded through
/// `core/security/sensitive_data_scrubber.dart`, so the Network tab, and its
/// Copy buttons, never hold the Authorization header, a password, an OTP or
/// a token. The values of the keys a request names as sensitive
/// ([sensitiveKeysOf]) are masked too.
class DevConsoleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }

    _addEntry(options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }

    final id = response.requestOptions.extra['_devConsoleId'] as String?;
    if (id != null) {
      DevConsoleStore.instance.updateNetworkEntry(
        id,
        (entry) => entry.copyWith(
          statusCode: response.statusCode,
          responseHeaders: _headersOf(response),
          responseBody: _responseBodyOf(response),
          endTime: DateTime.now(),
        ),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(err);
      return;
    }

    // A request rejected before it reached onRequest, as ConnectivityInterceptor rejects one while the device is
    // offline, has no entry yet: add it, so its failure is recorded like any other.
    final id = err.requestOptions.extra['_devConsoleId'] as String? ?? _addEntry(err.requestOptions);
    DevConsoleStore.instance.updateNetworkEntry(
      id,
      (entry) => entry.copyWith(
        statusCode: err.response?.statusCode,
        responseBody: _truncate(
          err.response?.data == null
              ? null
              : scrubErrorBody(
                  err.response?.data,
                  requestBody: err.requestOptions.data,
                  sensitiveKeys: sensitiveKeysOf(err.requestOptions),
                ),
        ),
        endTime: DateTime.now(),
        error: _describe(err),
      ),
    );
    handler.next(err);
  }

  /// Completes the entry of a request that failed with [err] and that an interceptor before this one answered with
  /// [response] instead, as `CacheInterceptor` answers a GET that cannot reach the server from its cache.
  ///
  /// Resolving a request in onError ends the error chain there, so neither [onError] nor [onResponse] of this
  /// interceptor sees it, and the entry its [onRequest] added would stay in flight for good. The entry shows
  /// [response] and keeps the error it answers. A request that never reached [onRequest], such as one rejected while
  /// the device is offline, has no entry and gets none: it was never sent.
  static void recordAnswer(DioException err, Response response) {
    if (!kDebugMode) return;

    final id = err.requestOptions.extra['_devConsoleId'] as String?;
    if (id == null) return;
    DevConsoleStore.instance.updateNetworkEntry(
      id,
      (entry) => entry.copyWith(
        statusCode: response.statusCode,
        responseHeaders: _headersOf(response),
        responseBody: _responseBodyOf(response),
        endTime: DateTime.now(),
        error: _describe(err),
      ),
    );
  }

  /// The error text of an entry: the type of [err] and its message, or the error it wraps when it has none, such as
  /// the dart:io exception of a connection reset.
  static String _describe(DioException err) => '${err.type.name}: ${err.message ?? err.error ?? 'Unknown error'}';

  /// The headers of [response] as the Network tab records them, with the value of every credential header masked.
  static Map<String, dynamic> _headersOf(Response response) =>
      maskHeaders(response.headers.map.map((k, v) => MapEntry(k, v.join(', '))));

  /// The body of [response] as the Network tab records it, without the credentials it may hold.
  static String? _responseBodyOf(Response response) => _truncate(
    response.data == null
        ? null
        : scrubBodyText(response.data, sensitiveKeys: sensitiveKeysOf(response.requestOptions)),
  );

  /// Records [options] in [DevConsoleStore] as a request in flight and returns the id of its entry.
  String _addEntry(RequestOptions options) {
    final id = '${options.method}_${options.uri}_${DateTime.now().microsecondsSinceEpoch}';
    options.extra['_devConsoleId'] = id;

    final entry = NetworkEntry(
      id: id,
      method: options.method,
      url: options.uri.toString(),
      startTime: DateTime.now(),
      requestHeaders: maskHeaders(options.headers),
      requestBody: options.data == null ? null : scrubBodyText(options.data, sensitiveKeys: sensitiveKeysOf(options)),
    );

    DevConsoleStore.instance.addNetworkEntry(entry);
    return id;
  }

  static String? _truncate(String? value, [int maxLength = 10000]) {
    if (value == null) return null;
    return value.length > maxLength ? '${value.substring(0, maxLength)}...[truncated]' : value;
  }
}
