import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';

/// Dio interceptor that records HTTP requests/responses to [DevConsoleStore].
///
/// Only active in debug mode — production builds skip entirely.
class DevConsoleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }

    final id = '${options.method}_${options.uri}_${DateTime.now().microsecondsSinceEpoch}';
    options.extra['_devConsoleId'] = id;

    final entry = NetworkEntry(
      id: id,
      method: options.method,
      url: options.uri.toString(),
      startTime: DateTime.now(),
      requestHeaders: Map<String, dynamic>.from(options.headers),
      requestBody: options.data?.toString(),
    );

    DevConsoleStore.instance.addNetworkEntry(entry);
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
          responseHeaders: response.headers.map.map((k, v) => MapEntry(k, v.join(', '))),
          responseBody: _truncate(response.data?.toString()),
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

    final id = err.requestOptions.extra['_devConsoleId'] as String?;
    if (id != null) {
      DevConsoleStore.instance.updateNetworkEntry(
        id,
        (entry) => entry.copyWith(
          statusCode: err.response?.statusCode,
          responseBody: _truncate(err.response?.data?.toString()),
          endTime: DateTime.now(),
          error: '${err.type.name}: ${err.message ?? 'Unknown error'}',
        ),
      );
    }
    handler.next(err);
  }

  String? _truncate(String? value, [int maxLength = 10000]) {
    if (value == null) return null;
    return value.length > maxLength ? '${value.substring(0, maxLength)}...[truncated]' : value;
  }
}
