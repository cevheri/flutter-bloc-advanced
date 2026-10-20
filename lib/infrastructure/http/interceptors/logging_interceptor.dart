import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';

/// Structured request/response logging via AppLogger.
///
/// Two modes:
/// * **Concise (default)** — one debug line per request/response carrying
///   only metadata (method, URI, header *names*, status, body *length*).
///   Cheap and safe to leave on in dev.
/// * **Verbose (opt-in via [verbose])** — additionally logs the full
///   request/response **body** and header *values*, with secrets stripped
///   through `core/security/sensitive_data_scrubber.dart`. Flip it on at
///   runtime (debug session, dev-console toggle) only while you need to
///   inspect a payload, then flip it back off.
///
/// The [formatRequest] / [formatResponse] builders are pure (no logging
/// side effect) so the redaction contract is unit-testable without
/// capturing console output. They run only when AppLogger prints the debug
/// line, so a production build never formats a request or a response.
class LoggingInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('Http');

  /// When true, [formatRequest] / [formatResponse] include the redacted
  /// body and header values. Defaults to false. Static so a single switch
  /// (code, debugger, or dev-console toggle) controls every request.
  static bool verbose = false;

  /// Cap on how many characters of a body are logged in verbose mode,
  /// mirroring the dev-console store's own truncation.
  static const int _maxBodyChars = 10000;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.debug('{}', [_LazyLogLine(() => formatRequest(options))]);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.debug('{}', [_LazyLogLine(() => formatResponse(response))]);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.error('{} {} -> ERROR: {} {}', [
      err.requestOptions.method,
      err.requestOptions.path,
      err.type.name,
      err.message ?? '',
    ]);
    handler.next(err);
  }

  /// Build the request log line. Concise unless [verbose] is set.
  static String formatRequest(RequestOptions options) {
    final concise = '${options.method} ${options.uri} (headers: ${options.headers.keys.join(', ')})';
    if (!verbose) return concise;

    final headers = scrubHeaders(options.headers);
    return '$concise headers: $headers body: ${_renderBody(options.data)}';
  }

  /// Build the response log line. Concise unless [verbose] is set.
  static String formatResponse(Response response) {
    final method = response.requestOptions.method;
    final path = response.requestOptions.path;
    final concise = '$method $path -> ${response.statusCode} (length: ${response.data?.toString().length ?? 0})';
    if (!verbose) return concise;

    return '$concise body: ${_renderBody(response.data)}';
  }

  /// Render a redacted, length-bounded representation of a request or
  /// response body. [scrubBodyText] masks the secret values of a Map, a List
  /// or a JSON string, which is how ApiClient receives every response, and
  /// then every JWT, so a token held in a non-secret-named field (or a raw
  /// string body) still never reaches the log.
  static String _renderBody(Object? body) => _truncate(scrubBodyText(body));

  static String _truncate(String value) {
    return value.length > _maxBodyChars ? '${value.substring(0, _maxBodyChars)}...[truncated]' : value;
  }
}

/// A log argument that builds its line in toString. AppLogger turns an
/// argument into text only for a level it prints, so the debug lines that
/// a production build drops are never built.
class _LazyLogLine {
  const _LazyLogLine(this._build);

  final String Function() _build;

  @override
  String toString() => _build();
}
