import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/idempotency_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake handler that captures the [RequestOptions] passed to [next]/[resolve].
class _RecordingRequestHandler extends RequestInterceptorHandler {
  RequestOptions? captured;
  @override
  void next(RequestOptions options) {
    captured = options;
  }
}

RequestOptions _opts({required String method, Map<String, dynamic>? extra, Map<String, dynamic>? headers}) {
  return RequestOptions(
    path: '/admin/users',
    method: method,
    extra: extra ?? <String, dynamic>{},
    headers: headers ?? <String, dynamic>{},
  );
}

void main() {
  group('IdempotencyInterceptor', () {
    late IdempotencyInterceptor interceptor;

    setUp(() {
      interceptor = IdempotencyInterceptor();
    });

    test('opt-out (no extra flag): does not set Idempotency-Key header', () {
      final options = _opts(method: 'POST');
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured!.headers.containsKey(IdempotencyInterceptor.headerName), isFalse);
      expect(handler.captured!.extra.containsKey(IdempotencyInterceptor.keyExtraKey), isFalse);
    });

    test('opt-in POST: attaches a UUID v4 Idempotency-Key header', () {
      final options = _opts(method: 'POST', extra: {IdempotencyInterceptor.optInExtraKey: true});
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      final header = handler.captured!.headers[IdempotencyInterceptor.headerName] as String?;
      expect(header, isNotNull);
      // UUID v4 length is 36 with 4 dashes.
      expect(header!.length, 36);
      expect(header.split('-').length, 5);
      // Persists key in extra for retry stability.
      expect(handler.captured!.extra[IdempotencyInterceptor.keyExtraKey], equals(header));
    });

    test('opt-in PUT: header is attached', () {
      final options = _opts(method: 'PUT', extra: {IdempotencyInterceptor.optInExtraKey: true});
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured!.headers[IdempotencyInterceptor.headerName], isA<String>());
    });

    test('opt-in PATCH: header is attached', () {
      final options = _opts(method: 'PATCH', extra: {IdempotencyInterceptor.optInExtraKey: true});
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured!.headers[IdempotencyInterceptor.headerName], isA<String>());
    });

    test('opt-in GET: header NOT attached (not a mutating verb)', () {
      final options = _opts(method: 'GET', extra: {IdempotencyInterceptor.optInExtraKey: true});
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured!.headers.containsKey(IdempotencyInterceptor.headerName), isFalse);
    });

    test('opt-in DELETE: header NOT attached (DELETE is idempotent by definition)', () {
      final options = _opts(method: 'DELETE', extra: {IdempotencyInterceptor.optInExtraKey: true});
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured!.headers.containsKey(IdempotencyInterceptor.headerName), isFalse);
    });

    test('retry pass: pre-existing key in extra is reused, NOT regenerated', () {
      const existingKey = 'fixed-key-from-prior-attempt';
      final options = _opts(
        method: 'POST',
        extra: {IdempotencyInterceptor.optInExtraKey: true, IdempotencyInterceptor.keyExtraKey: existingKey},
      );
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured!.headers[IdempotencyInterceptor.headerName], equals(existingKey));
      expect(handler.captured!.extra[IdempotencyInterceptor.keyExtraKey], equals(existingKey));
    });

    test('caller-supplied Idempotency-Key header is respected, not overwritten', () {
      const callerKey = 'caller-correlation-id';
      final options = _opts(
        method: 'POST',
        extra: {IdempotencyInterceptor.optInExtraKey: true},
        headers: {IdempotencyInterceptor.headerName: callerKey},
      );
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured!.headers[IdempotencyInterceptor.headerName], equals(callerKey));
      // Cached into extra so retries stay stable on the same key.
      expect(handler.captured!.extra[IdempotencyInterceptor.keyExtraKey], equals(callerKey));
    });

    test('cached extra key wins over a caller-supplied header on retry', () {
      const cachedKey = 'cached-from-first-attempt';
      final options = _opts(
        method: 'POST',
        extra: {IdempotencyInterceptor.optInExtraKey: true, IdempotencyInterceptor.keyExtraKey: cachedKey},
        headers: {IdempotencyInterceptor.headerName: 'stale-header'},
      );
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured!.headers[IdempotencyInterceptor.headerName], equals(cachedKey));
    });

    test('opt-in flag set to non-true value is treated as opt-out', () {
      final options = _opts(method: 'POST', extra: {IdempotencyInterceptor.optInExtraKey: 'yes'});
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured!.headers.containsKey(IdempotencyInterceptor.headerName), isFalse);
    });

    test('lowercase method (post) still treated as mutating', () {
      final options = _opts(method: 'post', extra: {IdempotencyInterceptor.optInExtraKey: true});
      final handler = _RecordingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured!.headers[IdempotencyInterceptor.headerName], isA<String>());
    });
  });
}
