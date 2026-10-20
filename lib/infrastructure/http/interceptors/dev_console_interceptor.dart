import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';

/// Dio interceptor that records HTTP requests/responses to [DevConsoleStore].
///
/// Only active in debug mode — production builds skip entirely.
///
/// Headers and bodies are recorded through
/// `core/security/sensitive_data_scrubber.dart`, so the Network tab, and its
/// Copy buttons, never hold the Authorization header, a password, an OTP or
/// a token.
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
          responseHeaders: maskHeaders(response.headers.map.map((k, v) => MapEntry(k, v.join(', ')))),
          responseBody: _truncate(response.data == null ? null : scrubBodyText(response.data)),
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
          err.response?.data == null ? null : scrubErrorBody(err.response?.data, requestBody: err.requestOptions.data),
        ),
        endTime: DateTime.now(),
        error: '${err.type.name}: ${err.message ?? 'Unknown error'}',
      ),
    );
    handler.next(err);
  }

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
      requestBody: options.data == null ? null : scrubBodyText(options.data),
    );

    DevConsoleStore.instance.addNetworkEntry(entry);
    return id;
  }

  String? _truncate(String? value, [int maxLength = 10000]) {
    if (value == null) return null;
    return value.length > maxLength ? '${value.substring(0, maxLength)}...[truncated]' : value;
  }
}
