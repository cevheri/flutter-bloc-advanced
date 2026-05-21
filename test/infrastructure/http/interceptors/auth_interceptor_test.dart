import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the three behaviors of [AuthInterceptor] that every outgoing
/// HTTP request depends on:
/// 1. JWT present → `Authorization: Bearer <token>` is attached.
/// 2. JWT absent or empty → no `Authorization` header is written.
/// 3. Secure read throws → request proceeds anonymously (does NOT
///    crash the interceptor chain).
///
/// The interceptor is the single most-called piece of code in the
/// project; running the chain through `Interceptor.onRequest` directly
/// with a synthetic handler keeps the assertions tight to behavior
/// and free of Dio/HTTP plumbing.
void main() {
  setUpAll(() {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  });

  group('AuthInterceptor.onRequest', () {
    test('attaches Bearer header when secure storage returns a token', () async {
      final interceptor = AuthInterceptor(secureStorage: _FixedSecureStorage('jwt-value'));

      final options = RequestOptions(path: '/api/account');
      final handler = _CapturingRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.passedOptions, isNotNull, reason: 'handler.next should be called');
      expect(handler.passedOptions!.headers['Authorization'], 'Bearer jwt-value');
    });

    test('omits Authorization header when secure storage returns null', () async {
      final interceptor = AuthInterceptor(secureStorage: _FixedSecureStorage(null));

      final options = RequestOptions(path: '/api/public/health');
      final handler = _CapturingRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.passedOptions!.headers.containsKey('Authorization'), isFalse);
    });

    test('omits Authorization header when secure storage returns empty string', () async {
      final interceptor = AuthInterceptor(secureStorage: _FixedSecureStorage(''));

      final options = RequestOptions(path: '/api/account');
      final handler = _CapturingRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.passedOptions!.headers.containsKey('Authorization'), isFalse);
    });

    test('does not crash when secure storage read throws — request proceeds anonymously', () async {
      final interceptor = AuthInterceptor(secureStorage: _ThrowingSecureStorage());

      final options = RequestOptions(path: '/api/account');
      final handler = _CapturingRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.passedOptions, isNotNull, reason: 'handler.next must still be called');
      expect(handler.passedOptions!.headers.containsKey('Authorization'), isFalse);
    });
  });
}

class _FixedSecureStorage implements ISecureStorage {
  _FixedSecureStorage(this._token);
  final String? _token;
  @override
  Future<String?> read(String key) async => _token;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
}

class _ThrowingSecureStorage implements ISecureStorage {
  @override
  Future<String?> read(String key) async => throw StateError('secure read failed');
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
}

class _CapturingRequestHandler extends RequestInterceptorHandler {
  RequestOptions? passedOptions;
  @override
  void next(RequestOptions requestOptions) {
    passedOptions = requestOptions;
    super.next(requestOptions);
  }
}
