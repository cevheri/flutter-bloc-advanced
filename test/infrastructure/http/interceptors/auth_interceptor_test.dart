import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the four behaviors of [AuthInterceptor] that every outgoing
/// HTTP request depends on:
/// 1. JWT present → `Authorization: Bearer <token>` is attached.
/// 2. JWT absent or empty → no `Authorization` header is written.
/// 3. Public endpoint (sign-in, OTP, registration, password reset) →
///    no `Authorization` header, whatever is stored.
/// 4. Secure read throws → request proceeds anonymously (does NOT
///    crash the interceptor chain).
/// 5. Any other request records the session generation it goes out
///    under, read before the token.
///
/// The interceptor is the single most-called piece of code in the
/// project; running the chain through `Interceptor.onRequest` directly
/// with a synthetic handler keeps the assertions tight to behavior
/// and free of Dio/HTTP plumbing.
void main() {
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

    test('does not attach the stored token to a public endpoint', () async {
      // The stored token may be a stale one left by an expired session, and a server that checks every token it
      // receives rejects the request when it is, even on an endpoint that needs none.
      final interceptor = AuthInterceptor(secureStorage: _FixedSecureStorage('stale-jwt'));

      for (final path in [
        '/authenticate',
        '/authenticate/send-otp',
        '/authenticate/verify-otp',
        '/register',
        '/account/reset-password/init',
      ]) {
        final handler = _CapturingRequestHandler();

        await interceptor.onRequest(RequestOptions(path: path, method: 'POST', extra: {'_basePath': path}), handler);

        expect(handler.passedOptions, isNotNull, reason: 'handler.next should be called for $path');
        expect(handler.passedOptions!.headers.containsKey('Authorization'), isFalse, reason: path);
      }
    });

    test('does not crash when secure storage read throws — request proceeds anonymously', () async {
      final interceptor = AuthInterceptor(secureStorage: _ThrowingSecureStorage());

      final options = RequestOptions(path: '/api/account');
      final handler = _CapturingRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.passedOptions, isNotNull, reason: 'handler.next must still be called');
      expect(handler.passedOptions!.headers.containsKey('Authorization'), isFalse);
    });

    // A logout can start and finish while the token is read, and the read still answers with the token of the session
    // that ended. The request has to count as sent under that session, so its 401 refreshes nothing.
    test('records the session generation before it reads the token', () async {
      final interceptor = AuthInterceptor(secureStorage: _WipeWhileReadingSecureStorage('jwt-value'));
      final handler = _CapturingRequestHandler();

      await interceptor.onRequest(RequestOptions(path: '/api/account'), handler);

      expect(handler.passedOptions!.headers['Authorization'], 'Bearer jwt-value');
      final sentUnder = AuthInterceptor.sessionGenerationOf(handler.passedOptions!);
      expect(sentUnder, isNotNull);
      expect(SessionGeneration.hasEnded(sentUnder!), isTrue);
    });
  });
}

/// Answers a read with [_token] only after a whole wipe of the stored session ran, as a read can when a logout starts
/// and finishes while the read is on its way.
class _WipeWhileReadingSecureStorage implements ISecureStorage {
  _WipeWhileReadingSecureStorage(this._token);
  final String _token;
  @override
  Future<String?> read(String key) async {
    await SessionGeneration.wipe(() async {});
    return _token;
  }

  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
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
