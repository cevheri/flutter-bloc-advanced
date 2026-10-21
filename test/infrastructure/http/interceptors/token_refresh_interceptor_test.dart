import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/rotated_tokens_take_back.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

/// ISecureStorage whose jwtToken read throws (refresh token is normal).
/// Exercises the stale-header check's graceful-fallback path.
class _ReadThrowsOnJwtSecureStorage implements ISecureStorage {
  final Map<String, String> _store = {};
  @override
  Future<String?> read(String key) async {
    if (key == SecureStorageKeys.jwtToken.key) throw StateError('boom on jwt read');
    return _store[key];
  }

  @override
  Future<void> write(String key, String value) async => _store[key] = value;
  @override
  Future<void> delete(String key) async => _store.remove(key);
  @override
  Future<void> deleteAll() async => _store.clear();
}

/// In-memory ISecureStorage for tests. Counts reads of the refresh-token
/// key, the proxy several tests use for whether a refresh started.
class _MemorySecureStorage implements ISecureStorage {
  final Map<String, String> _store = {};
  int refreshTokenReadCount = 0;
  @override
  Future<String?> read(String key) async {
    if (key == SecureStorageKeys.refreshToken.key) refreshTokenReadCount++;
    return _store[key];
  }

  @override
  Future<void> write(String key, String value) async => _store[key] = value;
  @override
  Future<void> delete(String key) async => _store.remove(key);
  @override
  Future<void> deleteAll() async => _store.clear();
}

/// A request to [path] as AuthInterceptor sends it, which records the session generation the request goes out under.
RequestOptions _sentRequest(String path, {String? method, Map<String, dynamic>? headers}) => RequestOptions(
  path: path,
  method: method,
  headers: headers,
  extra: {AuthInterceptor.sessionGenerationKey: SessionGeneration.current},
);

/// The public endpoints the app calls before sign-in: sign-in, OTP send and verify, registration and password reset,
/// and the app config the lifecycle checks read.
const _publicEndpoints = [
  ('POST', '/authenticate'),
  ('POST', '/authenticate/send-otp'),
  ('POST', '/authenticate/verify-otp'),
  ('POST', '/register'),
  ('POST', '/account/reset-password/init'),
  ('GET', '/app/config'),
];

void main() {
  late Dio dio;
  late _MemorySecureStorage secureStorage;

  setUp(() async {
    secureStorage = _MemorySecureStorage();
    dio = Dio(BaseOptions(baseUrl: 'https://test.api', responseType: ResponseType.plain));
  });

  tearDown(() async {
    dio.close();
  });

  group('TokenRefreshInterceptor', () {
    // Not a QueuedInterceptor: the retry after a refresh goes back through the same Dio, and a queued
    // onError would hold the retry's error behind the call waiting for it, so both would hang.
    // Concurrent 401s share one refresh through the in-flight Future instead.
    test('should be a plain Interceptor, not a QueuedInterceptor', () {
      final interceptor = TokenRefreshInterceptor(dio: dio);
      expect(interceptor, isA<Interceptor>());
      expect(interceptor, isNot(isA<QueuedInterceptor>()));
    });

    test('should accept optional onSessionExpired callback', () {
      // Should not throw with null callback
      final interceptor1 = TokenRefreshInterceptor(dio: dio);
      expect(interceptor1, isA<TokenRefreshInterceptor>());

      // Should not throw with provided callback
      final interceptor2 = TokenRefreshInterceptor(dio: dio, onSessionExpired: () {});
      expect(interceptor2, isA<TokenRefreshInterceptor>());
    });
  });

  group('TokenRefreshInterceptor - non-401 errors', () {
    test('should pass through 400 errors without attempting refresh', () async {
      final interceptor = TokenRefreshInterceptor(dio: dio);
      final handler = _TestErrorHandler();
      final requestOptions = RequestOptions(path: '/api/users');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 400, data: 'Bad Request'),
      );

      await interceptor.onError(error, handler);

      expect(handler.nextCalled, isTrue);
      expect(handler.resolveCalled, isFalse);
    });

    test('should pass through 500 errors without attempting refresh', () async {
      final interceptor = TokenRefreshInterceptor(dio: dio);
      final handler = _TestErrorHandler();
      final requestOptions = RequestOptions(path: '/api/users');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 500, data: 'Server Error'),
      );

      await interceptor.onError(error, handler);

      expect(handler.nextCalled, isTrue);
      expect(handler.resolveCalled, isFalse);
    });

    test('should pass through 403 errors without attempting refresh', () async {
      final interceptor = TokenRefreshInterceptor(dio: dio);
      final handler = _TestErrorHandler();
      final requestOptions = RequestOptions(path: '/api/users');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 403, data: 'Forbidden'),
      );

      await interceptor.onError(error, handler);

      expect(handler.nextCalled, isTrue);
    });

    test('should not call onSessionExpired for non-401 errors', () async {
      var sessionExpiredCalled = false;
      final interceptor = TokenRefreshInterceptor(dio: dio, onSessionExpired: () => sessionExpiredCalled = true);
      final handler = _TestErrorHandler();
      final requestOptions = RequestOptions(path: '/api/users');

      for (final statusCode in [400, 403, 404, 500, 502, 503]) {
        sessionExpiredCalled = false;

        final error = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: statusCode),
        );

        await interceptor.onError(error, handler);

        expect(sessionExpiredCalled, isFalse, reason: 'Should not expire session for $statusCode');
      }
    });

    test('should pass through errors with null response', () async {
      final interceptor = TokenRefreshInterceptor(dio: dio);
      final handler = _TestErrorHandler();
      final requestOptions = RequestOptions(path: '/api/users');

      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        // No response — null statusCode
      );

      await interceptor.onError(error, handler);

      expect(handler.nextCalled, isTrue);
    });
  });

  group('TokenRefreshInterceptor - 401 on refresh endpoint', () {
    test('should call onSessionExpired when refresh endpoint returns 401', () async {
      var sessionExpiredCalled = false;
      final interceptor = TokenRefreshInterceptor(dio: dio, onSessionExpired: () => sessionExpiredCalled = true);
      final handler = _TestErrorHandler();
      final requestOptions = RequestOptions(path: '/api/token/refresh');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );

      await interceptor.onError(error, handler);

      expect(sessionExpiredCalled, isTrue);
      expect(handler.nextCalled, isTrue);
    });

    test('should call handler.next (not reject) for 401 on refresh endpoint', () async {
      final interceptor = TokenRefreshInterceptor(dio: dio);
      final handler = _TestErrorHandler();
      final requestOptions = RequestOptions(path: '/api/token/refresh');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );

      await interceptor.onError(error, handler);

      expect(handler.nextCalled, isTrue);
      expect(handler.rejectCalled, isFalse);
      expect(handler.resolveCalled, isFalse);
    });

    test('should detect refresh endpoint path containing /api/token/refresh', () async {
      var sessionExpiredCalled = false;
      final interceptor = TokenRefreshInterceptor(dio: dio, onSessionExpired: () => sessionExpiredCalled = true);
      final handler = _TestErrorHandler();

      // Path that contains the refresh path
      final requestOptions = RequestOptions(path: '/v2/api/token/refresh');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );

      await interceptor.onError(error, handler);

      // Should still be detected as the refresh endpoint
      expect(sessionExpiredCalled, isTrue);
    });
  });

  group('TokenRefreshInterceptor - 401 from a public endpoint', () {
    // A public endpoint serves requests without a session, so its 401 rejects the credentials or input in the request.
    // A refresh would spend the stored refresh token on a wrong password.
    test('passes the 401 on without refreshing or ending the session', () async {
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'expired-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      var sessionExpiredCalls = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => sessionExpiredCalls++,
      );

      for (final (method, path) in _publicEndpoints) {
        // With a session generation recorded, as if the endpoint were not public, so only the public check stops the
        // refresh.
        final requestOptions = RequestOptions(
          path: path,
          method: method,
          extra: {'_basePath': path, AuthInterceptor.sessionGenerationKey: SessionGeneration.current},
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        );
        final handler = _TestErrorHandler();

        await interceptor.onError(error, handler);

        expect(handler.nextError, same(error), reason: '$method $path');
        expect(handler.resolveCalled, isFalse, reason: '$method $path');
      }
      expect(secureStorage.refreshTokenReadCount, 0, reason: 'the refresh-token read is the proxy for a refresh');
      expect(sessionExpiredCalls, 0);
    });

    // The public list held paths without methods, so a 401 from a protected request on the path of a public endpoint
    // would have been taken for rejected credentials and never refreshed the session. No shipped request sends one yet.
    test('refreshes the session for a 401 from another method on the path of a public endpoint', () async {
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      var refreshRequests = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        refreshDioFactory: (source) {
          refreshRequests++;
          return Dio(BaseOptions(baseUrl: source.options.baseUrl))
            ..interceptors.add(_StubInterceptor()..stubError(statusCode: 401));
        },
      );
      final requestOptions = RequestOptions(
        path: '/authenticate',
        method: 'GET',
        extra: {'_basePath': '/authenticate', AuthInterceptor.sessionGenerationKey: SessionGeneration.current},
      );
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );

      await interceptor.onError(error, _TestErrorHandler());

      expect(refreshRequests, 1);
    });
  });

  group('TokenRefreshInterceptor - 401 with no refresh token', () {
    test('should call onSessionExpired when no refresh token is stored', () async {
      var sessionExpiredCalled = false;
      final interceptor = TokenRefreshInterceptor(dio: dio, onSessionExpired: () => sessionExpiredCalled = true);
      final handler = _TestErrorHandler();
      final requestOptions = _sentRequest('/api/users');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );

      // No refresh token in storage
      await interceptor.onError(error, handler);

      expect(sessionExpiredCalled, isTrue);
      expect(handler.nextCalled, isTrue);
    });

    test('should call onSessionExpired when refresh token is empty string', () async {
      await secureStorage.write(SecureStorageKeys.refreshToken.key, '');

      var sessionExpiredCalled = false;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        onSessionExpired: () => sessionExpiredCalled = true,
        secureStorage: secureStorage,
      );
      final handler = _TestErrorHandler();
      final requestOptions = _sentRequest('/api/users');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );

      await interceptor.onError(error, handler);

      expect(sessionExpiredCalled, isTrue);
      expect(handler.nextCalled, isTrue);
    });
  });

  group('TokenRefreshInterceptor - 401 with refresh token', () {
    test('should attempt refresh and call onSessionExpired when refresh fails', () async {
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-jwt-token');

      var sessionExpiredCalled = false;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        onSessionExpired: () => sessionExpiredCalled = true,
        secureStorage: secureStorage,
      );
      final handler = _TestErrorHandler();
      final requestOptions = _sentRequest('/api/users');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );

      // The interceptor creates a fresh Dio to call /api/token/refresh.
      // Since there is no real server, the refresh will fail with a DioException,
      // triggering the session expired callback.
      await interceptor.onError(error, handler);

      expect(sessionExpiredCalled, isTrue);
      expect(handler.nextCalled, isTrue);
    });
  });

  group('TokenRefreshInterceptor - concurrent refresh coalescing', () {
    test('coalesces concurrent 401s into a single refresh request', () async {
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      var refreshRequests = 0;

      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        refreshDioFactory: (source) {
          refreshRequests++;
          return Dio(BaseOptions(baseUrl: source.options.baseUrl))
            ..interceptors.add(_StubInterceptor()..stubError(statusCode: 401));
        },
      );
      DioException makeErr() {
        final ro = _sentRequest('/api/users');
        return DioException(
          requestOptions: ro,
          response: Response(requestOptions: ro, statusCode: 401),
        );
      }

      final h1 = _TestErrorHandler();
      final h2 = _TestErrorHandler();
      final h3 = _TestErrorHandler();

      await Future.wait([
        interceptor.onError(makeErr(), h1),
        interceptor.onError(makeErr(), h2),
        interceptor.onError(makeErr(), h3),
      ]);

      // Without coalescing this would be 3, one refresh request per
      // concurrent 401. With the in-flight Future shared, all three
      // queued callers await the same refresh.
      expect(refreshRequests, 1, reason: 'concurrent 401s should share a single refresh attempt');
    });

    test('does not attempt a second refresh when the retried request 401s again', () async {
      // Simulates a request that has already been retried after a
      // refresh — RequestOptions.extra carries the _retriedAfterRefresh
      // marker. A second 401 must short-circuit to logout instead of
      // entering another refresh round (which would just rotate
      // tokens forever against a backend that keeps rejecting them).
      var sessionExpiredCalls = 0;
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      final baselineRefreshReads = secureStorage.refreshTokenReadCount;

      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => sessionExpiredCalls++,
      );
      final ro = _sentRequest('/api/users', headers: {'Authorization': 'Bearer SOME_JWT'});
      // Marker is an Expando keyed on RequestOptions (typed, per-
      // instance, no map collisions). debugMarkAsRetried is the
      // sanctioned test-only path to set it without driving a full
      // refresh+retry round.
      TokenRefreshInterceptor.debugMarkAsRetried(ro);
      final error = DioException(
        requestOptions: ro,
        response: Response(requestOptions: ro, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(sessionExpiredCalls, 1, reason: 'must surface logout on second 401');
      expect(handler.nextCalled, isTrue);
      expect(
        secureStorage.refreshTokenReadCount - baselineRefreshReads,
        0,
        reason: 'must NOT enter the refresh path — refresh-token read is the proxy',
      );
    });

    test('stale-header check survives a throwing secure read (graceful fallback)', () async {
      // Failing-but-readable secure store: jwtToken throws, refreshToken
      // exists. The stale-header optimization read should be swallowed
      // and we should fall through to the normal refresh path — letting
      // the throw escape would break the request pipeline.
      final flaky = _ReadThrowsOnJwtSecureStorage();
      await flaky.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');

      final interceptor = TokenRefreshInterceptor(dio: dio, secureStorage: flaky);
      final ro = _sentRequest('/api/users', headers: {'Authorization': 'Bearer OLD_JWT'});
      final error = DioException(
        requestOptions: ro,
        response: Response(requestOptions: ro, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      // Must NOT throw; falls through to refresh attempt which will
      // also fail (no real server), so onSessionExpired is reached.
      await interceptor.onError(error, handler);
      expect(handler.nextCalled, isTrue);
    });

    test('skips refresh when JWT was already rotated since the failing request was sent', () async {
      // Secure store already has the rotated token; the failing
      // request carries the previous one. Interceptor should detect
      // that and NOT call refresh again.
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'NEW_JWT');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      final baselineRefreshReads = secureStorage.refreshTokenReadCount;
      final retryStub = _CapturingSuccessStub();
      dio.interceptors.add(retryStub);

      final interceptor = TokenRefreshInterceptor(dio: dio, secureStorage: secureStorage);
      final requestOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer OLD_JWT'});
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(
        secureStorage.refreshTokenReadCount - baselineRefreshReads,
        0,
        reason: 'stale header path must NOT call refresh; refresh-token read is the proxy for that',
      );
      expect(retryStub.lastAuthorization, 'Bearer NEW_JWT');
    });

    test('clears in-flight Future so a later 401 starts a fresh refresh', () async {
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      final interceptor = TokenRefreshInterceptor(dio: dio, secureStorage: secureStorage);
      DioException makeErr() {
        final ro = _sentRequest('/api/users');
        return DioException(
          requestOptions: ro,
          response: Response(requestOptions: ro, statusCode: 401),
        );
      }

      // First wave completes…
      await interceptor.onError(makeErr(), _TestErrorHandler());
      final after1 = secureStorage.refreshTokenReadCount;

      // …then a later 401 (after the in-flight Future cleared) starts
      // its own refresh sequence.
      await interceptor.onError(makeErr(), _TestErrorHandler());
      final after2 = secureStorage.refreshTokenReadCount;

      expect(after2, greaterThan(after1), reason: 'next 401 must trigger a new refresh');
    });
  });

  group('TokenRefreshInterceptor - onSessionExpired null safety', () {
    test('should not crash when onSessionExpired is null on refresh endpoint 401', () async {
      final interceptor = TokenRefreshInterceptor(dio: dio);
      final handler = _TestErrorHandler();
      final requestOptions = RequestOptions(path: '/api/token/refresh');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );

      // Should not throw even without callback
      await interceptor.onError(error, handler);

      expect(handler.nextCalled, isTrue);
    });

    test('should not crash when onSessionExpired is null with no refresh token', () async {
      final interceptor = TokenRefreshInterceptor(dio: dio);
      final handler = _TestErrorHandler();
      final requestOptions = _sentRequest('/api/users');

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );

      // No refresh token, no callback — should not throw
      await interceptor.onError(error, handler);

      expect(handler.nextCalled, isTrue);
    });
  });

  group('TokenRefreshInterceptor - Dio integration', () {
    test('should pass through non-401 errors in Dio pipeline', () async {
      final stubInterceptor = _StubInterceptor();
      final interceptor = TokenRefreshInterceptor(dio: dio);

      dio.interceptors.addAll([stubInterceptor, interceptor]);
      stubInterceptor.stubError(statusCode: 400, data: 'Bad Request');

      await expectLater(
        () => dio.get('/api/users'),
        throwsA(predicate<DioException>((e) => e.response?.statusCode == 400)),
      );
    });

    test('should pass through 500 errors in Dio pipeline', () async {
      final stubInterceptor = _StubInterceptor();
      final interceptor = TokenRefreshInterceptor(dio: dio);

      dio.interceptors.addAll([stubInterceptor, interceptor]);
      stubInterceptor.stubError(statusCode: 500, data: 'Server Error');

      await expectLater(
        () => dio.get('/api/users'),
        throwsA(predicate<DioException>((e) => e.response?.statusCode == 500)),
      );
    });

    test('should not interfere with successful requests', () async {
      final stubInterceptor = _StubInterceptor();
      final interceptor = TokenRefreshInterceptor(dio: dio);

      dio.interceptors.addAll([stubInterceptor, interceptor]);
      stubInterceptor.stubSuccess(data: '{"result":"ok"}');

      final response = await dio.get('/api/users');

      expect(response.statusCode, 200);
      expect(response.data, '{"result":"ok"}');
    });

    test('logs out without a second refresh when the retry is rejected with 401 again', () async {
      // The retry comes back through this interceptor, where the retry marker ends the session. The call is
      // bounded because a queued interceptor used to hang here.
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      var refreshRequests = 0;
      var sessionExpiredCalls = 0;
      final server = _UnauthorizedServerStub();

      dio.interceptors.addAll([
        AuthInterceptor(secureStorage: secureStorage),
        TokenRefreshInterceptor(
          dio: dio,
          secureStorage: secureStorage,
          onSessionExpired: () => sessionExpiredCalls++,
          refreshDioFactory: (source) {
            refreshRequests++;
            final refreshDio = Dio(BaseOptions(baseUrl: source.options.baseUrl));
            refreshDio.interceptors.add(_StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt"}'));
            return refreshDio;
          },
        ),
        server,
      ]);

      await expectLater(
        dio
            .get<String>('/api/users', options: Options(headers: {'Authorization': 'Bearer old-jwt'}))
            .timeout(const Duration(seconds: 5)),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
      );

      expect(server.authorizations, ['Bearer old-jwt', 'Bearer new-jwt']);
      expect(sessionExpiredCalls, 1);
      expect(refreshRequests, 1, reason: 'exactly one refresh');
    });
  });

  group('TokenRefreshInterceptor - 401 followed by successful refresh', () {
    // Drives [TokenRefreshInterceptor.onError] directly (mirroring the
    // existing 401-with-refresh-token test) and short-circuits the
    // retry's _dio.fetch by adding a [_CapturingSuccessStub] to the
    // production Dio. This isolates the assertions to the interceptor's
    // own contract — no full Dio pipeline, no real HTTP.

    test('persists rotated tokens, retries original request with new Bearer, marker stamped', () async {
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');

      final retryStub = _CapturingSuccessStub();
      dio.interceptors.add(retryStub);

      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        refreshDioFactory: (source) {
          final refreshDio = Dio(BaseOptions(baseUrl: source.options.baseUrl));
          refreshDio.interceptors.add(
            _StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt","refresh_token":"new-refresh"}'),
          );
          return refreshDio;
        },
      );

      final requestOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer old-jwt'});
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      // Retry succeeded → resolve.
      expect(handler.resolveCalled, isTrue, reason: 'retried request must resolve, not surface 401');
      expect(handler.nextCalled, isFalse);

      // Retry used the rotated token and was marked.
      expect(retryStub.lastAuthorization, 'Bearer new-jwt');
      expect(retryStub.lastRetryMarker, isTrue);

      // Rotated tokens persisted, ready for next outgoing call.
      expect(await secureStorage.read(SecureStorageKeys.jwtToken.key), 'new-jwt');
      expect(await secureStorage.read(SecureStorageKeys.refreshToken.key), 'new-refresh');
    });

    test('persists only id_token when refresh response omits new refresh_token', () async {
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'still-valid-refresh');

      dio.interceptors.add(_CapturingSuccessStub());

      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        refreshDioFactory: (source) {
          final refreshDio = Dio(BaseOptions(baseUrl: source.options.baseUrl));
          refreshDio.interceptors.add(_StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt"}'));
          return refreshDio;
        },
      );

      final requestOptions = _sentRequest('/api/users');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      await interceptor.onError(error, _TestErrorHandler());

      expect(await secureStorage.read(SecureStorageKeys.jwtToken.key), 'new-jwt');
      expect(
        await secureStorage.read(SecureStorageKeys.refreshToken.key),
        'still-valid-refresh',
        reason: 'omitted refresh_token in response must leave the existing one intact',
      );
    });

    // Regression: a refresh response that is not valid JSON, such as one a proxy cut short and sent without a JSON
    // content type, failed to decode with a FormatException whose text quotes the body around the error, so the error
    // line, which every build of main_prod prints, carried the new access and refresh tokens.
    test('logs out on a malformed refresh response without logging its tokens', () async {
      AppLogger.configure(isProduction: true);
      addTearDown(() => AppLogger.configure(isProduction: false));
      final lines = <String>[];
      void collect(OutputEvent event) => lines.addAll(event.lines);
      Logger.addOutputListener(collect);
      addTearDown(() => Logger.removeOutputListener(collect));
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      var logoutCount = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => logoutCount++,
        refreshDioFactory: (source) {
          final refreshDio = Dio(BaseOptions(baseUrl: source.options.baseUrl));
          refreshDio.interceptors.add(
            _StubInterceptor()..stubSuccess(data: '{"id_token":"at-new-opaque-1122","refresh_token":"rt-new-77aa88'),
          );
          return refreshDio;
        },
      );
      final requestOptions = _sentRequest('/api/users');

      await interceptor.onError(
        DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        ),
        _TestErrorHandler(),
      );

      expect(logoutCount, 1);
      expect(lines, anyElement(contains('FormatException')));
      expect(lines, everyElement(allOf(isNot(contains('at-new-opaque-1122')), isNot(contains('rt-new-77aa88')))));
    });

    // Regression: the refresh Dio decoded a response with a JSON content type itself, so a malformed one failed with
    // the FormatException of the platform's parser instead of decodeCredentialJson's. On the web its message is the
    // browser's text for the error, which repeats the characters around it, tokens included.
    test('decodes a refresh response with a JSON content type through decodeCredentialJson', () async {
      AppLogger.configure(isProduction: true);
      addTearDown(() => AppLogger.configure(isProduction: false));
      final lines = <String>[];
      void collect(OutputEvent event) => lines.addAll(event.lines);
      Logger.addOutputListener(collect);
      addTearDown(() => Logger.removeOutputListener(collect));
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      dio.httpClientAdapter = _JsonBodyAdapter('{"id_token":at-new-opaque-1122,"refresh_token":"rt-new-77aa88"}');
      var logoutCount = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => logoutCount++,
      );
      final requestOptions = _sentRequest('/api/users');

      await interceptor.onError(
        DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        ),
        _TestErrorHandler(),
      );

      expect(logoutCount, 1);
      expect(lines, anyElement(contains('FormatException: Malformed JSON (at offset 12)')));
      expect(lines, everyElement(allOf(isNot(contains('at-new-opaque-1122')), isNot(contains('rt-new-77aa88')))));
    });

    test('logs out when refresh response is missing id_token', () async {
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');

      var logoutCount = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => logoutCount++,
        refreshDioFactory: (source) {
          final refreshDio = Dio(BaseOptions(baseUrl: source.options.baseUrl));
          refreshDio.interceptors.add(_StubInterceptor()..stubSuccess(data: '{}'));
          return refreshDio;
        },
      );

      final requestOptions = _sentRequest('/api/users');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(logoutCount, 1, reason: 'malformed refresh response must trigger session-expired');
      expect(handler.nextCalled, isTrue, reason: 'original 401 must surface');
      // Original token unchanged; no garbage persisted.
      expect(await secureStorage.read(SecureStorageKeys.jwtToken.key), 'old-jwt');
    });

    test('logs out when refresh response returns id_token=""', () async {
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');

      var logoutCount = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => logoutCount++,
        refreshDioFactory: (source) {
          final refreshDio = Dio(BaseOptions(baseUrl: source.options.baseUrl));
          refreshDio.interceptors.add(_StubInterceptor()..stubSuccess(data: '{"id_token":""}'));
          return refreshDio;
        },
      );

      final requestOptions = _sentRequest('/api/users');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      await interceptor.onError(error, _TestErrorHandler());

      expect(logoutCount, 1);
      expect(await secureStorage.read(SecureStorageKeys.jwtToken.key), 'old-jwt');
    });

    test('logs out (no crash) when refresh response is a JSON array instead of an object', () async {
      // Defense against backend/proxy misconfiguration: if the body is
      // a JSON array (or any non-Map shape), parsing must not crash
      // the interceptor — surface as session-expired with a
      // diagnosable log.
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');

      var logoutCount = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => logoutCount++,
        refreshDioFactory: (source) {
          final refreshDio = Dio(BaseOptions(baseUrl: source.options.baseUrl));
          refreshDio.interceptors.add(_StubInterceptor()..stubSuccess(data: '["not", "a", "map"]'));
          return refreshDio;
        },
      );

      final requestOptions = _sentRequest('/api/users');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(logoutCount, 1, reason: 'non-object body must trigger session-expired');
      expect(handler.nextCalled, isTrue);
      expect(await secureStorage.read(SecureStorageKeys.jwtToken.key), 'old-jwt', reason: 'no garbage persisted');
    });

    test('rolls back rotated tokens to prior values when refresh_token write throws', () async {
      // Setup: prior tokens exist. Refresh returns new pair. Secure
      // storage succeeds writing the new id_token but throws on the
      // refresh_token write. The interceptor must restore both keys
      // to their prior values so the user re-authenticates cleanly
      // instead of running with a torn id/refresh pair.
      final torn = _RefreshWriteFailsSecureStorage();
      await torn.seed(jwt: 'prior-jwt', refresh: 'prior-refresh');

      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: torn,
        refreshDioFactory: (source) {
          final refreshDio = Dio(BaseOptions(baseUrl: source.options.baseUrl));
          refreshDio.interceptors.add(
            _StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt","refresh_token":"new-refresh"}'),
          );
          return refreshDio;
        },
      );

      final requestOptions = _sentRequest('/api/users');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      // The failed persist must surface as session-expired, not as a
      // half-applied rotation.
      expect(handler.nextCalled, isTrue, reason: 'original 401 must surface after rollback');
      expect(handler.resolveCalled, isFalse);

      // Both keys restored to prior values — no torn pair.
      expect(await torn.read(SecureStorageKeys.jwtToken.key), 'prior-jwt');
      expect(await torn.read(SecureStorageKeys.refreshToken.key), 'prior-refresh');
    });
  });

  // A logout or the idle timeout wipes the stored session and starts a new session generation. A refresh that was on
  // its way stored the rotated tokens after the wipe, so a relaunch restored the session the user had ended.
  // AuthInterceptor records on each request the session generation it is sent under. A refresh for a request whose
  // session a logout or the end of the session wiped, or is wiping, would spend a refresh token on a session that is
  // over, or on the one the user signed in to since.
  group('TokenRefreshInterceptor - the session a request was sent under', () {
    test('does not refresh while the session the request was sent under is being wiped', () async {
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      var sessionExpiredCalls = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => sessionExpiredCalls++,
      );
      // The wipe has started but not yet deleted the stored tokens when the request goes out.
      final releaseWipe = Completer<void>();
      final wipe = SessionGeneration.wipe(() => releaseWipe.future);
      final requestOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer old-jwt'});
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);
      releaseWipe.complete();
      await wipe;

      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(secureStorage.refreshTokenReadCount, 0, reason: 'the refresh-token read is the proxy for a refresh');
      expect(sessionExpiredCalls, 0);
    });

    test('fails a 401 for a request without a session generation and spends no refresh token', () async {
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      var sessionExpiredCalls = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => sessionExpiredCalls++,
      );
      // Not sent through AuthInterceptor, so nothing shows which session it belongs to.
      final requestOptions = RequestOptions(path: '/api/users');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(secureStorage.refreshTokenReadCount, 0, reason: 'the refresh-token read is the proxy for a refresh');
      expect(sessionExpiredCalls, 0);
    });

    // Regression: the stale-header check ran first, so the 401 of a request that one user sent, arriving after that
    // user signed out and another signed in, sent the request again with the token of the user signed in now.
    test('does not send a request again with the token of a user who signed in after its session ended', () async {
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'user-a-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'user-a-refresh');
      final retryStub = _CapturingSuccessStub();
      dio.interceptors.add(retryStub);
      var sessionExpiredCalls = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => sessionExpiredCalls++,
      );
      final requestOptions = _sentRequest('/account', method: 'POST', headers: {'Authorization': 'Bearer user-a-jwt'});
      // User A signs out while the request is on its way, and user B signs in.
      await SessionGeneration.wipe(() async {
        await secureStorage.delete(SecureStorageKeys.jwtToken.key);
        await secureStorage.delete(SecureStorageKeys.refreshToken.key);
      });
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'user-b-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'user-b-refresh');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(retryStub.lastAuthorization, isNull, reason: 'the action user A started must not run as user B');
      expect(secureStorage.refreshTokenReadCount, 0, reason: 'the refresh-token read is the proxy for a refresh');
      expect(sessionExpiredCalls, 0, reason: 'ending the session would sign out user B');
    });

    test('does not send a request without a session generation again with the token stored now', () async {
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'stored-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      final retryStub = _CapturingSuccessStub();
      dio.interceptors.add(retryStub);
      final interceptor = TokenRefreshInterceptor(dio: dio, secureStorage: secureStorage);
      // Not sent through AuthInterceptor, so nothing shows that the token stored now is of the session it was sent
      // under.
      final requestOptions = RequestOptions(path: '/api/users', headers: {'Authorization': 'Bearer sent-jwt'});
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(retryStub.lastAuthorization, isNull);
    });

    test('does not end the session signed in since when a request sent again after a refresh gets 401 again', () async {
      var sessionExpiredCalls = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => sessionExpiredCalls++,
      );
      final requestOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer refreshed-jwt'});
      TokenRefreshInterceptor.debugMarkAsRetried(requestOptions);
      // The session ends while the request is sent again, and the user signs in again.
      await SessionGeneration.wipe(() async {});
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'signed-in-jwt');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'signed-in-refresh');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(sessionExpiredCalls, 0, reason: 'ending the session would sign out the session signed in since');
    });
  });

  group('TokenRefreshInterceptor - session ended during the refresh', () {
    /// What the session wipe does: it deletes the stored tokens inside [SessionGeneration.wipe].
    Future<void> endSession(ISecureStorage storage) => SessionGeneration.wipe(() async {
      await storage.delete(SecureStorageKeys.jwtToken.key);
      await storage.delete(SecureStorageKeys.refreshToken.key);
    });

    DioException unauthorized() {
      final requestOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer old-jwt'});
      return DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
    }

    test('drops the rotated tokens and fails the request when the session ends before the refresh answers', () async {
      final storage = _InterleavingSecureStorage();
      await storage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await storage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      final retryStub = _CapturingSuccessStub();
      dio.interceptors.add(retryStub);
      var sessionExpiredCalls = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: storage,
        onSessionExpired: () => sessionExpiredCalls++,
        refreshDioFactory: (source) => Dio(BaseOptions(baseUrl: source.options.baseUrl))
          ..interceptors.add(
            _RefreshInFlightStub(
              body: '{"id_token":"new-jwt","refresh_token":"new-refresh"}',
              whileInFlight: () => endSession(storage),
            ),
          ),
      );
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(handler.resolveCalled, isFalse);
      expect(retryStub.lastAuthorization, isNull, reason: 'the request is not sent again with the dropped token');
      // Never stored, not even for a moment: an app closed right then would keep them.
      expect(storage.writes, ['jwtToken=old-jwt', 'refreshToken=valid-refresh']);
      expect(await storage.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await storage.read(SecureStorageKeys.refreshToken.key), isNull);
      // The session already ended, and a new one may have started since: ending it again would sign that one out.
      expect(sessionExpiredCalls, 0);
    });

    test('takes back the rotated tokens when the session ends while they are being stored', () async {
      final storage = _InterleavingSecureStorage();
      await storage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await storage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      // The wipe runs while the rotated JWT is being written, so the rotated refresh token lands after it.
      storage.onWrite = (key) async {
        if (key == SecureStorageKeys.jwtToken.key) await endSession(storage);
      };
      final retryStub = _CapturingSuccessStub();
      dio.interceptors.add(retryStub);
      var sessionExpiredCalls = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: storage,
        onSessionExpired: () => sessionExpiredCalls++,
        refreshDioFactory: (source) => Dio(BaseOptions(baseUrl: source.options.baseUrl))
          ..interceptors.add(
            _StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt","refresh_token":"new-refresh"}'),
          ),
      );
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(retryStub.lastAuthorization, isNull);
      expect(await storage.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await storage.read(SecureStorageKeys.refreshToken.key), isNull);
      expect(sessionExpiredCalls, 0);
    });

    test('ends the session when the rotated tokens cannot be taken back', () async {
      final storage = _InterleavingSecureStorage();
      await storage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await storage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      storage.onWrite = (key) async {
        if (key != SecureStorageKeys.jwtToken.key) return;
        await endSession(storage);
        storage.failDeletes = true;
      };
      dio.interceptors.add(_CapturingSuccessStub());
      var sessionExpiredCalls = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: storage,
        onSessionExpired: () => sessionExpiredCalls++,
        refreshDioFactory: (source) => Dio(BaseOptions(baseUrl: source.options.baseUrl))
          ..interceptors.add(
            _StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt","refresh_token":"new-refresh"}'),
          ),
      );
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      // The rotated refresh token is still stored, so the session is ended again, which wipes it.
      expect(await storage.read(SecureStorageKeys.refreshToken.key), 'new-refresh');
      expect(sessionExpiredCalls, 1);
      expect(handler.nextError, same(error));
    });

    test('leaves the tokens of a session stored after the end alone', () async {
      final storage = _InterleavingSecureStorage();
      await storage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await storage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      // The session ends while the rotated JWT is being written, and the user signs in again before the refresh
      // token is written.
      storage.onWrite = (key) async {
        if (key != SecureStorageKeys.jwtToken.key) return;
        await endSession(storage);
        await storage.write(SecureStorageKeys.jwtToken.key, 'signed-in-jwt');
        await storage.write(SecureStorageKeys.refreshToken.key, 'signed-in-refresh');
      };
      dio.interceptors.add(_CapturingSuccessStub());
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: storage,
        refreshDioFactory: (source) =>
            Dio(BaseOptions(baseUrl: source.options.baseUrl))
              ..interceptors.add(_StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt"}')),
      );

      await interceptor.onError(unauthorized(), _TestErrorHandler());

      expect(await storage.read(SecureStorageKeys.jwtToken.key), 'signed-in-jwt');
      expect(await storage.read(SecureStorageKeys.refreshToken.key), 'signed-in-refresh');
    });

    // Regression: a refresh that failed after the session ended still ended the session, which wiped the session the
    // user had signed in to while the refresh was on its way.
    test('does not end the session signed in after the end when the refresh then fails', () async {
      final storage = _InterleavingSecureStorage();
      await storage.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await storage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      var sessionExpiredCalls = 0;
      final interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: storage,
        onSessionExpired: () => sessionExpiredCalls++,
        refreshDioFactory: (source) => Dio(BaseOptions(baseUrl: source.options.baseUrl))
          ..interceptors.add(
            _RefreshInFlightStub(
              statusCode: 401,
              whileInFlight: () async {
                await endSession(storage);
                await storage.write(SecureStorageKeys.jwtToken.key, 'signed-in-jwt');
                await storage.write(SecureStorageKeys.refreshToken.key, 'signed-in-refresh');
              },
            ),
          ),
      );
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(sessionExpiredCalls, 0, reason: 'ending the session would wipe the session signed in to since');
      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(await storage.read(SecureStorageKeys.jwtToken.key), 'signed-in-jwt');
      expect(await storage.read(SecureStorageKeys.refreshToken.key), 'signed-in-refresh');
    });
  });

  // On web every browser tab of the app runs its own interceptor and counts its own session generation, but all of
  // them read and write the same stored session. A refresh on its way in one tab stored its answer after another tab
  // signed out, so the session came back for every tab, or over the tokens another tab had just rotated; and when the
  // server refused the refresh token that tab had just used, it ended the session that tab had refreshed.
  group('TokenRefreshInterceptor - another browser tab', () {
    late _SharedLocalStorage localStorage;
    late _TabStorage thisTab;
    late _TabStorage otherTab;
    late _CapturingSuccessStub retryStub;
    late int sessionExpiredCalls;

    setUp(() async {
      localStorage = _SharedLocalStorage();
      thisTab = localStorage.openTab();
      otherTab = localStorage.openTab();
      await thisTab.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await thisTab.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      otherTab.receive();
      retryStub = _CapturingSuccessStub();
      dio.interceptors.add(retryStub);
      sessionExpiredCalls = 0;
    });

    DioException unauthorized() {
      final requestOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer old-jwt'});
      return DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
    }

    /// The interceptor of this tab, whose refresh request is answered with [statusCode] and [body] once [whileInFlight]
    /// has run.
    TokenRefreshInterceptor interceptorOfThisTab({
      required Future<void> Function() whileInFlight,
      int statusCode = 200,
      String body = '{"id_token":"new-jwt","refresh_token":"new-refresh"}',
    }) => TokenRefreshInterceptor(
      dio: dio,
      secureStorage: thisTab,
      onSessionExpired: () => sessionExpiredCalls++,
      refreshDioFactory: (source) =>
          Dio(BaseOptions(baseUrl: source.options.baseUrl))
            ..interceptors.add(_RefreshInFlightStub(statusCode: statusCode, body: body, whileInFlight: whileInFlight)),
    );

    /// A 401 in the other tab, which that tab's own interceptor fixes with a token refresh: the server rotates the
    /// tokens to that tab's, and the interceptor stores the JWT, then the refresh token.
    Future<void> refreshInOtherTab() async {
      final otherDio = Dio(BaseOptions(baseUrl: 'https://test.api'))..interceptors.add(_CapturingSuccessStub());
      addTearDown(otherDio.close);
      final interceptorOfOtherTab = TokenRefreshInterceptor(
        dio: otherDio,
        secureStorage: otherTab,
        refreshDioFactory: (source) => Dio(BaseOptions(baseUrl: source.options.baseUrl))
          ..interceptors.add(
            _StubInterceptor()
              ..stubSuccess(data: '{"id_token":"jwt-of-other-tab","refresh_token":"refresh-of-other-tab"}'),
          ),
      );
      await interceptorOfOtherTab.onError(unauthorized(), _TestErrorHandler());
    }

    /// What a sign-out in the other tab does to the stored session: it deletes the JWT, then the refresh token. The
    /// wipe runs in that tab's own session generation, so the test deletes the tokens without SessionGeneration.wipe,
    /// which would end the generation of this tab too.
    Future<void> signOutInOtherTab() async {
      await otherTab.delete(SecureStorageKeys.jwtToken.key);
      await otherTab.delete(SecureStorageKeys.refreshToken.key);
    }

    test('drops the rotated tokens when the other tab signs out while the refresh is on its way', () async {
      final interceptor = interceptorOfThisTab(
        whileInFlight: () async {
          await signOutInOtherTab();
          thisTab.receive();
        },
      );
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(localStorage.values, isEmpty, reason: 'the session the other tab ended stays ended');
      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(retryStub.lastAuthorization, isNull);
      expect(sessionExpiredCalls, 0, reason: 'what is stored now is not the session this refresh was for');
    });

    test('does not end the session when the other tab signs out while a failing refresh is on its way', () async {
      final interceptor = interceptorOfThisTab(
        statusCode: 503,
        body: '',
        whileInFlight: () async {
          await signOutInOtherTab();
          thisTab.receive();
        },
      );
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      // A session the user signs in to next may hold no refresh token, so ending the session here could wipe it.
      expect(sessionExpiredCalls, 0, reason: 'what is stored now is not the session this refresh was for');
      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(localStorage.values, isEmpty);
    });

    test('keeps the tokens the other tab rotated while the refresh was on its way and retries with them', () async {
      final interceptor = interceptorOfThisTab(
        whileInFlight: () async {
          await refreshInOtherTab();
          thisTab.receive();
        },
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(unauthorized(), handler);

      expect(localStorage.values, {
        SecureStorageKeys.jwtToken.key: 'jwt-of-other-tab',
        SecureStorageKeys.refreshToken.key: 'refresh-of-other-tab',
      });
      expect(handler.resolveCalled, isTrue);
      expect(retryStub.lastAuthorization, 'Bearer jwt-of-other-tab');
      expect(sessionExpiredCalls, 0);
    });

    test('keeps the session the other tab refreshed when the server refuses the refresh token it replaced', () async {
      // A server that accepts a refresh token once refuses the second tab that sends it.
      final interceptor = interceptorOfThisTab(
        statusCode: 401,
        body: '',
        whileInFlight: () async {
          await refreshInOtherTab();
          thisTab.receive();
        },
      );
      final handler = _TestErrorHandler();

      await interceptor.onError(unauthorized(), handler);

      expect(sessionExpiredCalls, 0, reason: 'ending the session would sign out the tab that refreshed it');
      expect(handler.resolveCalled, isTrue);
      expect(retryStub.lastAuthorization, 'Bearer jwt-of-other-tab');
      expect(localStorage.values, {
        SecureStorageKeys.jwtToken.key: 'jwt-of-other-tab',
        SecureStorageKeys.refreshToken.key: 'refresh-of-other-tab',
      });
    });

    test('drops the answer when the other tab refreshed the session and has begun to sign out', () async {
      final interceptor = interceptorOfThisTab(
        whileInFlight: () async {
          await refreshInOtherTab();
          // The sign-out has deleted the JWT but not yet the refresh token.
          await otherTab.delete(SecureStorageKeys.jwtToken.key);
          thisTab.receive();
        },
      );
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(localStorage.values, {SecureStorageKeys.refreshToken.key: 'refresh-of-other-tab'});
      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(retryStub.lastAuthorization, isNull);
      expect(sessionExpiredCalls, 0);
    });

    test('still ends the session when the refresh fails and no other tab has changed it', () async {
      final interceptor = interceptorOfThisTab(statusCode: 401, body: '', whileInFlight: () async {});
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(sessionExpiredCalls, 1);
      expect(handler.nextError, same(error));
    });
  });

  // A tab sees another tab's change to localStorage only some time after it was made. A refresh that checked the stored
  // session before the other tab's sign-out reached this tab stored its rotated tokens after that sign-out, and the
  // session came back for every tab.
  group('TokenRefreshInterceptor - session end told by another browser tab', () {
    late _SharedLocalStorage localStorage;
    late _TabStorage thisTab;
    late _TabStorage otherTab;
    late _SessionEndChannel channel;
    late _TabSessionEndSignal thisTabSignal;
    late _TabSessionEndSignal otherTabSignal;
    late _CapturingSuccessStub retryStub;
    late int sessionExpiredCalls;

    setUp(() async {
      localStorage = _SharedLocalStorage();
      thisTab = localStorage.openTab();
      otherTab = localStorage.openTab();
      await thisTab.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await thisTab.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      otherTab.receive();
      channel = _SessionEndChannel();
      thisTabSignal = channel.openTab(storage: thisTab);
      otherTabSignal = channel.openTab();
      retryStub = _CapturingSuccessStub();
      dio.interceptors.add(retryStub);
      sessionExpiredCalls = 0;
    });

    /// The interceptor of this tab, whose rotation answers [rotated] once [whileRotating] has run. With [rotation],
    /// that rotation instead.
    TokenRefreshInterceptor interceptorOfThisTab({
      Future<void> Function()? whileRotating,
      TokensRotated rotated = const TokensRotated(accessToken: 'new-jwt', refreshToken: 'new-refresh'),
      TokenRotation? rotation,
      Duration copyCatchUpLimit = RotatedTokensTakeBack.defaultCopyCatchUpLimit,
    }) {
      final takeBack = RotatedTokensTakeBack(
        secureStorage: thisTab,
        sessionEndSignal: thisTabSignal,
        copyCatchUpLimit: copyCatchUpLimit,
      );
      // A wipe still waiting for this tab's copy would end the session generation of the next test too.
      addTearDown(takeBack.dispose);
      return TokenRefreshInterceptor(
        dio: dio,
        secureStorage: thisTab,
        rotation: rotation ?? _FakeRotation(rotated, whileRotating: whileRotating),
        takeBack: takeBack,
        onSessionExpired: () => sessionExpiredCalls++,
      );
    }

    /// What a sign-out in the other tab does: it tells the other tabs, then wipes the stored session, [keys] in their
    /// order. The wipe runs in that tab's own session generation, so the test deletes the keys without
    /// SessionGeneration.wipe, which would end the generation of this tab too.
    Future<void> signOutInOtherTab({
      DateTime? at,
      List<SecureStorageKeys> keys = const [SecureStorageKeys.jwtToken, SecureStorageKeys.refreshToken],
    }) async {
      otherTabSignal.notifyEndedAt(at ?? DateTime.now());
      for (final key in keys) {
        await otherTab.delete(key.key);
      }
    }

    Future<void> signInInOtherTab() async {
      await otherTab.write(SecureStorageKeys.jwtToken.key, 'signed-in-jwt');
      await otherTab.write(SecureStorageKeys.refreshToken.key, 'signed-in-refresh');
    }

    DioException unauthorized() {
      final requestOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer old-jwt'});
      return DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
    }

    test('drops the answer when the end reaches this tab before the wipe does', () async {
      final interceptor = interceptorOfThisTab(
        whileRotating: () async {
          await signOutInOtherTab();
          await thisTabSignal.deliver();
        },
      );
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(localStorage.values, isEmpty, reason: 'the session the other tab ended stays ended');
      expect(handler.nextError, same(error), reason: 'the request fails with its 401');
      expect(retryStub.lastAuthorization, isNull);
      expect(sessionExpiredCalls, 0);
    });

    test('takes back the rotated tokens it stored after the wipe when the end reaches this tab', () async {
      // The wipe reaches the browser's copy before the rotated tokens, but not this tab's copy before the check.
      final interceptor = interceptorOfThisTab(whileRotating: signOutInOtherTab);
      await interceptor.onError(unauthorized(), _TestErrorHandler());
      expect(localStorage.values, isNotEmpty, reason: 'the rotated tokens landed after the wipe');

      await thisTabSignal.deliver();

      expect(localStorage.values, isEmpty, reason: 'the session the other tab ended stays ended');
      expect(sessionExpiredCalls, 0);
    });

    test('takes back the ID token and expiry an oidc refresh stored after the wipe', () async {
      const oidcKeys = [
        SecureStorageKeys.jwtToken,
        SecureStorageKeys.refreshToken,
        SecureStorageKeys.oidcIdToken,
        SecureStorageKeys.accessTokenExpiresAt,
      ];
      await thisTab.write(SecureStorageKeys.oidcIdToken.key, 'old-id-token');
      await thisTab.write(SecureStorageKeys.accessTokenExpiresAt.key, '1');
      otherTab.receive();
      final interceptor = interceptorOfThisTab(
        rotated: TokensRotated(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
          oidcIdToken: 'new-id-token',
          accessTokenExpiresAt: DateTime.utc(2026, 10, 21, 12, 30),
        ),
        whileRotating: () => signOutInOtherTab(keys: oidcKeys),
      );
      await interceptor.onError(unauthorized(), _TestErrorHandler());
      expect(localStorage.values.keys, containsAll(oidcKeys.map((key) => key.key)));

      await thisTabSignal.deliver();

      expect(localStorage.values, isEmpty, reason: 'every key the refresh stored is taken back');
    });

    test('leaves the session the other tab signed in to since alone', () async {
      final interceptor = interceptorOfThisTab(whileRotating: signOutInOtherTab);
      await interceptor.onError(unauthorized(), _TestErrorHandler());
      await signInInOtherTab();
      thisTab.receive();

      await thisTabSignal.deliver();

      expect(localStorage.values, {
        SecureStorageKeys.jwtToken.key: 'signed-in-jwt',
        SecureStorageKeys.refreshToken.key: 'signed-in-refresh',
      });
    });

    test('leaves tokens stored well before the wipe to the wipe, even when this tab has not seen it yet', () async {
      final interceptor = interceptorOfThisTab();
      await interceptor.onError(unauthorized(), _TestErrorHandler());
      // Later the user signs out and in again in the other tab, while this tab, in the background, has not taken the
      // changes yet. Its copy still holds the tokens it stored.
      otherTab.receive();
      await signOutInOtherTab(at: DateTime.now().add(const Duration(minutes: 5)));
      await signInInOtherTab();

      await thisTabSignal.deliver();

      expect(localStorage.values, {
        SecureStorageKeys.jwtToken.key: 'signed-in-jwt',
        SecureStorageKeys.refreshToken.key: 'signed-in-refresh',
      });
    });

    test('ends the session here when the rotated tokens cannot be taken back', () async {
      final interceptor = interceptorOfThisTab(whileRotating: signOutInOtherTab);
      await interceptor.onError(unauthorized(), _TestErrorHandler());
      thisTab.failDeletes = true;

      await thisTabSignal.deliver();

      expect(sessionExpiredCalls, 1, reason: 'ending the session wipes what is stored');
    });

    // The end message and the other tab's deletes reach this tab on separate channels, and the message usually comes
    // first. A 401 in that gap must not refresh with the refresh token this tab's copy still shows: the other tab has
    // deleted it, and the rotated tokens would land after the wipe, with no later end to take them back.
    test(
      'sends no refresh for a 401 that comes after the end was heard and before this tab\'s copy shows it',
      () async {
        final rotation = _FakeRotation(const TokensRotated(accessToken: 'new-jwt', refreshToken: 'new-refresh'));
        final interceptor = interceptorOfThisTab(rotation: rotation);
        await signOutInOtherTab();
        await thisTabSignal.deliver();
        // A request this tab sends now, still with the JWT its copy shows, gets a 401 before the deletes arrive.
        final error = unauthorized();
        final handler = _TestErrorHandler();

        await interceptor.onError(error, handler);
        thisTab.receive();
        await _settleTakeBack();

        expect(rotation.sent, isEmpty, reason: 'the refresh token the other tab deleted is not sent');
        expect(handler.nextError, same(error), reason: 'the request fails with its 401');
        expect(retryStub.lastAuthorization, isNull, reason: 'nothing is sent again');
        expect(localStorage.values, isEmpty, reason: 'the session the other tab ended stays ended');
        expect(sessionExpiredCalls, 0);
      },
    );

    test('refreshes nothing before or after this tab\'s copy shows the end of the other tab', () async {
      final rotation = _FakeRotation(const TokensRotated(accessToken: 'new-jwt', refreshToken: 'new-refresh'));
      final interceptor = interceptorOfThisTab(rotation: rotation);
      await signOutInOtherTab();
      await thisTabSignal.deliver();
      final whileBehind = _TestErrorHandler();
      await interceptor.onError(unauthorized(), whileBehind);

      thisTab.receive();
      await _settleTakeBack();
      final error = unauthorized();
      final onceCaughtUp = _TestErrorHandler();
      await interceptor.onError(error, onceCaughtUp);

      expect(rotation.sent, isEmpty);
      expect(whileBehind.nextCalled, isTrue);
      expect(onceCaughtUp.nextError, same(error), reason: 'no refresh token is stored, so the session cannot go on');
      expect(retryStub.lastAuthorization, isNull);
      expect(localStorage.values, isEmpty);
    });

    test('keeps a session the other tab signs in to while this tab waits for its copy to show the end', () async {
      final rotation = _FakeRotation(const TokensRotated(accessToken: 'new-jwt', refreshToken: 'new-refresh'));
      final interceptor = interceptorOfThisTab(rotation: rotation);
      await signOutInOtherTab();
      await thisTabSignal.deliver();
      await signInInOtherTab();

      thisTab.receive();
      await _settleTakeBack();

      expect(localStorage.values, {
        SecureStorageKeys.jwtToken.key: 'signed-in-jwt',
        SecureStorageKeys.refreshToken.key: 'signed-in-refresh',
      });
      expect(
        SessionGeneration.hasEnded(SessionGeneration.current),
        isFalse,
        reason: 'the wipe ended once the copy showed the end',
      );
      final requestOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer signed-in-jwt'});
      await interceptor.onError(
        DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        ),
        _TestErrorHandler(),
      );
      expect(rotation.sent, ['signed-in-refresh'], reason: 'the session signed in to since refreshes as usual');
    });

    test('ends its wipe after copyCatchUpLimit when this tab\'s copy never shows the end', () async {
      final warnings = _recordLogs(Level.warning);
      interceptorOfThisTab(copyCatchUpLimit: const Duration(milliseconds: 20));
      // The other tab told the end, but its deletes failed, so they never reach this tab.
      otherTabSignal.notifyEndedAt(DateTime.now());
      await thisTabSignal.deliver();
      expect(SessionGeneration.hasEnded(SessionGeneration.current), isTrue, reason: 'the wipe waits for the copy');

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(SessionGeneration.hasEnded(SessionGeneration.current), isFalse);
      expect(warnings.join('\n'), contains('did not show the end of another tab within 20 ms'));
    });
  });

  // On web two tabs that get a 401 at about the same time both refresh. A server that accepts each refresh token once
  // refuses the second, and a tab that cannot see the winner's write yet ends the session, which the session end
  // signal then carries to the winner too. The refreshes take turns across the tabs instead.
  group('TokenRefreshInterceptor - one refresh at a time across browser tabs', () {
    late _SharedLocalStorage localStorage;
    late _TabStorage thisTab;
    late _TabStorage otherTab;
    late _BrowserLock browserLock;
    late int sessionExpiredCalls;

    setUp(() async {
      localStorage = _SharedLocalStorage();
      thisTab = localStorage.openTab();
      otherTab = localStorage.openTab();
      await thisTab.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await thisTab.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      otherTab.receive();
      browserLock = _BrowserLock();
      sessionExpiredCalls = 0;
    });

    /// The interceptor of the tab that reads and writes [storage], with its own Dio, refreshing through [rotation]
    /// under [lock], the tab's view of [browserLock] unless given.
    _TabUnderTest tab(_TabStorage storage, TokenRotation rotation, {ITokenRefreshLock? lock}) {
      final retries = _CapturingSuccessStub();
      final tabDio = Dio(BaseOptions(baseUrl: 'https://test.api'))..interceptors.add(retries);
      addTearDown(tabDio.close);
      return _TabUnderTest(
        TokenRefreshInterceptor(
          dio: tabDio,
          secureStorage: storage,
          rotation: rotation,
          refreshLock: lock ?? browserLock.openTab(storage),
          onSessionExpired: () => sessionExpiredCalls++,
        ),
        retries,
      );
    }

    test('sends one refresh for two tabs that get a 401 at the same time', () async {
      final server = _OneTimeRefreshServer();
      final first = tab(thisTab, server);
      final second = tab(otherTab, server);

      await Future.wait([first.unauthorized(), second.unauthorized()]);

      expect(server.sent, ['valid-refresh']);
      expect(first.retries.lastAuthorization, 'Bearer jwt-1');
      expect(second.retries.lastAuthorization, 'Bearer jwt-1');
    });

    test('retries with the JWT another tab stored while this tab waited for the lock, without a refresh', () async {
      // A server that does not rotate refresh tokens: the stored refresh token stays the same, only the JWT changes.
      final server = _OneTimeRefreshServer(rotatesRefreshTokens: false);
      final first = tab(thisTab, server);
      final second = tab(otherTab, server);

      await Future.wait([first.unauthorized(), second.unauthorized()]);

      expect(server.sent, ['valid-refresh'], reason: 'the second tab sees the new JWT once granted');
      expect(second.retries.lastAuthorization, 'Bearer jwt-1');
      expect(sessionExpiredCalls, 0);
    });

    test('does not sign out the second tab when the server allows each refresh token once', () async {
      final server = _OneTimeRefreshServer();
      final first = tab(thisTab, server);
      final second = tab(otherTab, server);

      await Future.wait([first.unauthorized(), second.unauthorized()]);

      expect(sessionExpiredCalls, 0);
      expect(_tokensIn(localStorage), {
        SecureStorageKeys.jwtToken.key: 'jwt-1',
        SecureStorageKeys.refreshToken.key: 'refresh-1',
      });
    });

    test(
      'does not sign out the second tab when its copy shows the other tab\'s refresh only after the grant',
      () async {
        // Measured in Chromium: about one grant in ten reaches the tab before the previous holder's writes do.
        final server = _OneTimeRefreshServer();
        final first = tab(thisTab, server);
        final second = tab(
          otherTab,
          server,
          lock: browserLock.openTab(
            otherTab,
            catchUpOnGrant: false,
            onGranted: () => Timer(const Duration(milliseconds: 5), otherTab.receive),
          ),
        );

        await Future.wait([first.unauthorized(), second.unauthorized()]);

        expect(server.sent, ['valid-refresh']);
        expect(sessionExpiredCalls, 0);
        expect(second.retries.lastAuthorization, 'Bearer jwt-1');
      },
    );

    test('fails the request and keeps the session when this tab\'s copy does not catch up in time', () async {
      final server = _OneTimeRefreshServer();
      final first = tab(thisTab, server);
      final second = tab(
        otherTab,
        server,
        lock: browserLock.openTab(otherTab, catchUpOnGrant: false, catchUpLimit: const Duration(milliseconds: 20)),
      );

      await Future.wait([first.unauthorized(), second.unauthorized()]);

      expect(server.sent, ['valid-refresh'], reason: 'a refresh from a copy that is behind could send a spent token');
      expect(second.handler.rejectedError?.error, isA<TokenRefreshLockException>());
      expect(second.handler.nextCalled, isFalse, reason: 'rejected, so no later interceptor sends it again');
      expect(second.retries.lastAuthorization, isNull);
      expect(sessionExpiredCalls, 0, reason: 'nothing was sent for this request, so nothing refused the session');
      expect(_tokensIn(localStorage), {
        SecureStorageKeys.jwtToken.key: 'jwt-1',
        SecureStorageKeys.refreshToken.key: 'refresh-1',
      });
    });

    test('fails the request and keeps the session when the lock cannot be taken', () async {
      final server = _OneTimeRefreshServer();
      final only = tab(thisTab, server, lock: browserLock.openTab(thisTab, refuse: true));

      await only.unauthorized();

      expect(server.sent, isEmpty);
      expect(only.handler.rejectedError?.error, isA<TokenRefreshLockException>());
      expect(only.handler.nextCalled, isFalse);
      expect(sessionExpiredCalls, 0);
      expect(_tokensIn(localStorage), {
        SecureStorageKeys.jwtToken.key: 'old-jwt',
        SecureStorageKeys.refreshToken.key: 'valid-refresh',
      });
    });

    test('sends no refresh and ends nothing when this tab\'s session ended while it waited for the lock', () async {
      final server = _OneTimeRefreshServer();
      // A logout in this tab while another tab held the lock: the turn starts after the session ended.
      final only = tab(thisTab, server, lock: browserLock.openTab(thisTab, onGranted: _wipeTheSession));

      await only.unauthorized();

      expect(server.sent, isEmpty, reason: 'a refresh now could spend the refresh token of a session signed in since');
      expect(only.handler.nextError?.response?.statusCode, 401, reason: 'the request fails with its 401');
      expect(only.retries.lastAuthorization, isNull);
      expect(sessionExpiredCalls, 0, reason: 'the session is over already, and every tab was told once');
    });

    test('sends no refresh and ends nothing when this tab\'s session ends while its turn reads the JWT', () async {
      final server = _OneTimeRefreshServer();
      final retries = _CapturingSuccessStub();
      final tabDio = Dio(BaseOptions(baseUrl: 'https://test.api'))..interceptors.add(retries);
      addTearDown(tabDio.close);
      // The 401 reads the JWT once before the lock and once in its turn; the logout starts during the second read.
      final only = _TabUnderTest(
        TokenRefreshInterceptor(
          dio: tabDio,
          secureStorage: _WipeOnReadStorage(thisTab, SecureStorageKeys.jwtToken.key, readNumber: 2),
          rotation: server,
          refreshLock: browserLock.openTab(thisTab),
          onSessionExpired: () => sessionExpiredCalls++,
        ),
        retries,
      );

      await only.unauthorized();

      expect(server.sent, isEmpty);
      expect(only.handler.nextError?.response?.statusCode, 401);
      expect(sessionExpiredCalls, 0);
    });

    test('sends no refresh and keeps the session when this tab\'s copy stays behind for two 401s in a row', () async {
      final server = _OneTimeRefreshServer();
      final first = tab(thisTab, server);
      final second = tab(
        otherTab,
        server,
        lock: browserLock.openTab(otherTab, catchUpOnGrant: false, catchUpLimit: const Duration(milliseconds: 20)),
      );
      await Future.wait([first.unauthorized(), second.unauthorized()]);

      // Another request of the lagging tab gets its 401 after the first turn gave up; the copy still shows valid-refresh.
      final again = _TestErrorHandler();
      final requestOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer old-jwt'});
      await second.interceptor.onError(
        DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        ),
        again,
      );

      expect(server.sent, ['valid-refresh'], reason: 'the lagging copy would send the spent refresh token');
      expect(again.rejectedError?.error, isA<TokenRefreshLockException>());
      expect(sessionExpiredCalls, 0, reason: 'a refusal of the spent token would sign out every tab');
      expect(_tokensIn(localStorage), {
        SecureStorageKeys.jwtToken.key: 'jwt-1',
        SecureStorageKeys.refreshToken.key: 'refresh-1',
      });

      // Once the other tab's writes reach the copy, the next 401 retries with the JWT they hold.
      otherTab.receive();
      final caughtUp = _TestErrorHandler();
      final laterOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer old-jwt'});
      await second.interceptor.onError(
        DioException(
          requestOptions: laterOptions,
          response: Response(requestOptions: laterOptions, statusCode: 401),
        ),
        caughtUp,
      );

      expect(caughtUp.resolveCalled, isTrue);
      expect(second.retries.lastAuthorization, 'Bearer jwt-1');
      expect(server.sent, ['valid-refresh']);
    });

    test('sends one oidc grant for two tabs, and stores the ID token and expiry once', () async {
      final expiresAt = DateTime.utc(2026, 10, 21, 12, 30);
      await thisTab.write(SecureStorageKeys.oidcIdToken.key, 'old-id-token');
      await thisTab.write(
        SecureStorageKeys.accessTokenExpiresAt.key,
        encodeAccessTokenExpiry(DateTime.utc(2026, 10, 21, 12)),
      );
      otherTab.receive();
      final provider = _OneTimeOidcProvider(expiresAt);
      final first = tab(thisTab, OidcTokenRotation(client: _OidcClientOf(provider), secureStorage: thisTab));
      final second = tab(otherTab, OidcTokenRotation(client: _OidcClientOf(provider), secureStorage: otherTab));

      await Future.wait([first.unauthorized(), second.unauthorized()]);

      expect(provider.grants, ['valid-refresh']);
      expect(sessionExpiredCalls, 0);
      expect(first.retries.lastAuthorization, 'Bearer access-1');
      expect(second.retries.lastAuthorization, 'Bearer access-1');
      expect(_tokensIn(localStorage), {
        SecureStorageKeys.jwtToken.key: 'access-1',
        SecureStorageKeys.refreshToken.key: 'refresh-1',
        SecureStorageKeys.oidcIdToken.key: 'id-token-1',
        SecureStorageKeys.accessTokenExpiresAt.key: encodeAccessTokenExpiry(expiresAt),
      });
    });
  });

  // The interceptor sends the refresh through a TokenRotation: BackendTokenRotation in jwt mode, the OIDC client in
  // oidc mode. Its result decides what happens to the session: TokensRotated stores them, RotationRefused ends the
  // session, and RotationUnavailable keeps the session and fails the request as a network error.
  group('TokenRefreshInterceptor - with a rotation strategy', () {
    final expiresAt = DateTime.utc(2026, 10, 21, 12, 30);
    final priorExpiresAt = DateTime.utc(2026, 10, 21, 12);
    late _KeyRecordingSecureStorage storage;
    late _CapturingSuccessStub retryStub;
    late int sessionExpiredCalls;

    setUp(() async {
      storage = _KeyRecordingSecureStorage();
      await storage.write(SecureStorageKeys.jwtToken.key, 'old-access');
      await storage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      storage.writes.clear();
      storage.touched.clear();
      retryStub = _CapturingSuccessStub();
      sessionExpiredCalls = 0;
    });

    /// Seeds the OIDC ID token and the expiry of the session that is stored before the refresh.
    Future<void> seedOidcKeys() async {
      await storage.write(SecureStorageKeys.oidcIdToken.key, 'prior-id');
      await storage.write(SecureStorageKeys.accessTokenExpiresAt.key, encodeAccessTokenExpiry(priorExpiresAt));
      storage.writes.clear();
      storage.touched.clear();
    }

    TokenRefreshInterceptor interceptorWith(TokenRotation rotation) => TokenRefreshInterceptor(
      dio: dio,
      secureStorage: storage,
      onSessionExpired: () => sessionExpiredCalls++,
      rotation: rotation,
    );

    DioException unauthorized([String path = '/api/users']) {
      final requestOptions = _sentRequest(path, headers: {'Authorization': 'Bearer old-access'});
      return DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
    }

    /// What the wipe of an oidc session does: it deletes every stored key inside [SessionGeneration.wipe].
    Future<void> endSession() => SessionGeneration.wipe(() async {
      for (final key in SecureStorageKeys.values) {
        await storage.delete(key.key);
      }
    });

    final rotatedWithOidcKeys = TokensRotated(
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
      oidcIdToken: 'new-id',
      accessTokenExpiresAt: expiresAt,
    );

    test('TokensRotated with an ID token and an expiry stores all four keys, then retries', () async {
      dio.interceptors.add(retryStub);
      final rotation = _FakeRotation(rotatedWithOidcKeys);
      final handler = _TestErrorHandler();

      await interceptorWith(rotation).onError(unauthorized(), handler);

      expect(rotation.sent, ['valid-refresh']);
      expect(storage.writes, [
        'jwtToken=new-access',
        'refreshToken=new-refresh',
        'oidcIdToken=new-id',
        'accessTokenExpiresAt=${encodeAccessTokenExpiry(expiresAt)}',
      ], reason: 'the bearer, the refresh token, the ID token and the expiry, in this order');
      expect(handler.resolveCalled, isTrue);
      expect(retryStub.lastAuthorization, 'Bearer new-access');
      expect(sessionExpiredCalls, 0);
    });

    test('RotationRefused ends the session once and fails the request with its 401', () async {
      final rotation = _FakeRotation(const RotationRefused());
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptorWith(rotation).onError(error, handler);

      expect(rotation.sent, hasLength(1));
      expect(sessionExpiredCalls, 1);
      expect(handler.nextError, same(error));
      expect(await storage.read(SecureStorageKeys.jwtToken.key), 'old-access');
    });

    test('RotationUnavailable keeps the session and fails the request as a network error', () async {
      final rotation = _FakeRotation(const RotationUnavailable());
      final server = _UnauthorizedServerStub();
      dio.interceptors.addAll([AuthInterceptor(secureStorage: storage), interceptorWith(rotation), server]);

      await expectLater(
        dio.get<String>('/api/users').timeout(const Duration(seconds: 5)),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.connectionError)
              .having((e) => e.message, 'message', 'The identity provider could not be reached'),
        ),
      );

      expect(sessionExpiredCalls, 0);
      expect(rotation.sent, hasLength(1));
      expect(server.authorizations, ['Bearer old-access'], reason: 'the request is not sent again');
      expect(await storage.read(SecureStorageKeys.jwtToken.key), 'old-access');
      expect(await storage.read(SecureStorageKeys.refreshToken.key), 'valid-refresh');
    });

    // The network error would otherwise reach ResilienceInterceptor, which sends a GET again: its 401 would start
    // another rotation, against a provider that has just not answered.
    test('RotationUnavailable for a GET is not retried by ResilienceInterceptor', () async {
      addTearDown(ResilienceInterceptor.instance.resetAll);
      final rotation = _FakeRotation(const RotationUnavailable());
      final server = _UnauthorizedServerStub();
      dio.interceptors.addAll([
        AuthInterceptor(secureStorage: storage),
        interceptorWith(rotation),
        ResilienceInterceptor.instance.forDio(dio),
        server,
      ]);

      await expectLater(
        dio.get<String>('/api/users').timeout(const Duration(seconds: 10)),
        throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.connectionError)),
      );

      expect(rotation.sent, hasLength(1));
      expect(server.authorizations, hasLength(1));
      expect(sessionExpiredCalls, 0);
    });

    test('a failed write of the expiry restores the prior bearer, refresh token, ID token and expiry', () async {
      await seedOidcKeys();
      storage.failWriteOf = SecureStorageKeys.accessTokenExpiresAt.key;
      dio.interceptors.add(retryStub);
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptorWith(_FakeRotation(rotatedWithOidcKeys)).onError(error, handler);

      expect(await storage.read(SecureStorageKeys.jwtToken.key), 'old-access');
      expect(await storage.read(SecureStorageKeys.refreshToken.key), 'valid-refresh');
      expect(await storage.read(SecureStorageKeys.oidcIdToken.key), 'prior-id');
      expect(await storage.read(SecureStorageKeys.accessTokenExpiresAt.key), encodeAccessTokenExpiry(priorExpiresAt));
      expect(sessionExpiredCalls, 1);
      expect(handler.nextError, same(error));
      expect(retryStub.lastAuthorization, isNull);
    });

    test('a session ended while the rotated tokens are stored takes back the ID token and the expiry', () async {
      await seedOidcKeys();
      // The wipe runs while the rotated bearer is being written, so the rest of the rotated tokens land after it.
      storage.onWrite = (key) async {
        if (key == SecureStorageKeys.jwtToken.key) await endSession();
      };
      dio.interceptors.add(retryStub);
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptorWith(_FakeRotation(rotatedWithOidcKeys)).onError(error, handler);

      expect(storage.writes, contains('oidcIdToken=new-id'), reason: 'the ID token landed after the wipe');
      expect(storage.writes, contains('accessTokenExpiresAt=${encodeAccessTokenExpiry(expiresAt)}'));
      for (final key in SecureStorageKeys.values) {
        expect(await storage.read(key.key), isNull, reason: '${key.key} must be taken back');
      }
      expect(sessionExpiredCalls, 0);
      expect(handler.nextError, same(error));
      expect(retryStub.lastAuthorization, isNull);
    });

    test('TokensRotated without an ID token or an expiry touches only the bearer and the refresh token', () async {
      dio.interceptors.add(retryStub);

      await interceptorWith(_FakeRotation(const TokensRotated(accessToken: 'new-access', refreshToken: 'new-refresh')))
          .onError(unauthorized(), _TestErrorHandler());

      expect(storage.writes, ['jwtToken=new-access', 'refreshToken=new-refresh']);
      expect(storage.touched, {SecureStorageKeys.jwtToken.key, SecureStorageKeys.refreshToken.key});
    });

    test('TokensRotated without an ID token or an expiry rolls back only the bearer and the refresh token', () async {
      storage.failWriteOf = SecureStorageKeys.refreshToken.key;

      await interceptorWith(_FakeRotation(const TokensRotated(accessToken: 'new-access', refreshToken: 'new-refresh')))
          .onError(unauthorized(), _TestErrorHandler());

      expect(await storage.read(SecureStorageKeys.jwtToken.key), 'old-access');
      expect(sessionExpiredCalls, 1);
      expect(storage.touched, {SecureStorageKeys.jwtToken.key, SecureStorageKeys.refreshToken.key});
    });

    test('TokensRotated without an ID token or an expiry takes back only the bearer and the refresh token', () async {
      storage.onWrite = (key) async {
        if (key != SecureStorageKeys.jwtToken.key) return;
        await SessionGeneration.wipe(() async {
          await storage.delete(SecureStorageKeys.jwtToken.key);
          await storage.delete(SecureStorageKeys.refreshToken.key);
        });
      };

      await interceptorWith(_FakeRotation(const TokensRotated(accessToken: 'new-access', refreshToken: 'new-refresh')))
          .onError(unauthorized(), _TestErrorHandler());

      expect(await storage.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await storage.read(SecureStorageKeys.refreshToken.key), isNull);
      expect(storage.touched, {SecureStorageKeys.jwtToken.key, SecureStorageKeys.refreshToken.key});
    });

    test('two concurrent 401s share one rotation', () async {
      dio.interceptors.add(retryStub);
      final release = Completer<void>();
      final rotation = _FakeRotation(rotatedWithOidcKeys, whileRotating: () => release.future);
      final interceptor = interceptorWith(rotation);
      final first = _TestErrorHandler();
      final second = _TestErrorHandler();

      final both = Future.wait([
        interceptor.onError(unauthorized('/api/users'), first),
        interceptor.onError(unauthorized('/api/authorities'), second),
      ]);
      await pumpEventQueue();
      release.complete();
      await both;

      expect(rotation.sent, hasLength(1));
      expect(first.resolveCalled, isTrue);
      expect(second.resolveCalled, isTrue);
    });

    test('with no stored refresh token a 401 ends the session and never calls rotate', () async {
      await storage.delete(SecureStorageKeys.refreshToken.key);
      final rotation = _FakeRotation(rotatedWithOidcKeys);
      final error = unauthorized();
      final handler = _TestErrorHandler();

      await interceptorWith(rotation).onError(error, handler);

      expect(rotation.sent, isEmpty);
      expect(sessionExpiredCalls, 1);
      expect(handler.nextError, same(error));
    });
  });

  // A backend such as LibreDB Studio also answers 401 when a database or a model refuses its own credentials. Only its
  // AUTH_REQUIRED code means the bearer is no longer valid, so the app narrows the predicate to it.
  group('TokenRefreshInterceptor - with a narrowed 401 predicate', () {
    bool authRequired(DioException error) {
      final body = error.response?.data;
      if (error.response?.statusCode != 401 || body is! String || body.isEmpty) return false;
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> && decoded['code'] == 'AUTH_REQUIRED';
    }

    late _FakeRotation rotation;
    late int sessionExpiredCalls;
    late TokenRefreshInterceptor interceptor;

    setUp(() async {
      await secureStorage.write(SecureStorageKeys.jwtToken.key, 'old-access');
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh');
      dio.interceptors.add(_CapturingSuccessStub());
      rotation = _FakeRotation(const TokensRotated(accessToken: 'new-access'));
      sessionExpiredCalls = 0;
      interceptor = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: () => sessionExpiredCalls++,
        rotation: rotation,
        isSessionExpired: authRequired,
      );
    });

    DioException unauthorizedWith(String body) {
      final requestOptions = _sentRequest('/api/db/query', headers: {'Authorization': 'Bearer old-access'});
      return DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401, data: body),
      );
    }

    test('passes a 401 the predicate refuses on with no rotation and no end of the session', () async {
      final error = unauthorizedWith('{"code":"AUTH_ERROR"}');
      final handler = _TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(handler.nextError, same(error));
      expect(rotation.sent, isEmpty);
      expect(secureStorage.refreshTokenReadCount, 0, reason: 'the refresh-token read is the proxy for a refresh');
      expect(sessionExpiredCalls, 0);
    });

    test('still refreshes a 401 the predicate accepts', () async {
      final handler = _TestErrorHandler();

      await interceptor.onError(unauthorizedWith('{"code":"AUTH_REQUIRED"}'), handler);

      expect(rotation.sent, ['valid-refresh']);
      expect(handler.resolveCalled, isTrue);
      expect(sessionExpiredCalls, 0);
    });
  });
}

/// In-memory ISecureStorage that records its writes as `key=value` and runs [onWrite], once, after it applies a write
/// and before the write completes, as a call that runs while the write is still on its way does. With [failDeletes]
/// set, its deletes throw.
class _InterleavingSecureStorage extends _MemorySecureStorage {
  Future<void> Function(String key)? onWrite;
  final writes = <String>[];

  /// When true, every delete throws, as a store that fails does.
  bool failDeletes = false;

  @override
  Future<void> delete(String key) async {
    if (failDeletes) throw StateError('boom on delete $key');
    await super.delete(key);
  }

  @override
  Future<void> write(String key, String value) async {
    writes.add('$key=$value');
    await super.write(key, value);
    final hook = onWrite;
    onWrite = null;
    if (hook != null) await hook(key);
  }
}

/// Answers the refresh request with [statusCode] and [body] once [whileInFlight] has run, which stands for what the app
/// does while the refresh request is on its way. A status other than 200 is rejected, as the server's error response.
class _RefreshInFlightStub extends Interceptor {
  _RefreshInFlightStub({this.body = '', this.statusCode = 200, required this.whileInFlight});

  final String body;
  final int statusCode;
  final Future<void> Function() whileInFlight;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await whileInFlight();
    final response = Response(requestOptions: options, statusCode: statusCode, data: body);
    if (statusCode == 200) {
      handler.resolve(response);
      return;
    }
    handler.reject(DioException(requestOptions: options, type: DioExceptionType.badResponse, response: response));
  }
}

/// The localStorage that every browser tab of the app shares, opened by each tab as a [_TabStorage].
///
/// [values] is the browser's copy, which takes every change in the order the tabs make it. Each tab reads a copy of its
/// own, which takes another tab's change only when [_TabStorage.receive] delivers it, as in a browser that keeps a copy
/// of localStorage in the process of each tab and updates it from the other tabs later.
class _SharedLocalStorage {
  final values = <String, String>{};
  final _tabs = <_TabStorage>[];
  int _changes = 0;

  _TabStorage openTab() {
    final tab = _TabStorage._(this);
    _tabs.add(tab);
    return tab;
  }
}

/// A browser tab's view of [_SharedLocalStorage]. A change made here reaches this tab's copy and the browser's copy at
/// once, and the other tabs when they receive it.
class _TabStorage implements ISecureStorage {
  _TabStorage._(this._shared) : _copy = Map.of(_shared.values);

  final _SharedLocalStorage _shared;
  final Map<String, String> _copy;

  /// The number of the latest change this tab's copy holds for each key.
  final _changeOfKey = <String, int>{};
  final _undelivered = <({String key, String? value, int change})>[];

  /// The key of each change [receive] applies, once it is applied, as the browser's `storage` event in the tab.
  final _received = StreamController<String>.broadcast(sync: true);
  Stream<String> get received => _received.stream;

  /// Applies the changes the other tabs made since the last delivery, in their order. A change older than the one this
  /// tab's copy holds for the key is skipped: the browser's copy holds the later one.
  void receive() {
    final changes = List.of(_undelivered);
    _undelivered.clear();
    for (final change in changes) {
      if ((_changeOfKey[change.key] ?? 0) > change.change) continue;
      _take(change.key, change.value, change.change);
      _received.add(change.key);
    }
  }

  /// Reads [key] from this tab's copy at once, as `localStorage.getItem` does.
  String? readNow(String key) => _copy[key];

  /// Writes [key] at once, as `localStorage.setItem` does.
  void writeNow(String key, String value) => _change(key, value);

  void _take(String key, String? value, int change) {
    if (value == null) {
      _copy.remove(key);
    } else {
      _copy[key] = value;
    }
    _changeOfKey[key] = change;
  }

  void _change(String key, String? value) {
    final change = ++_shared._changes;
    _take(key, value, change);
    if (value == null) {
      _shared.values.remove(key);
    } else {
      _shared.values[key] = value;
    }
    for (final tab in _shared._tabs) {
      if (!identical(tab, this)) tab._undelivered.add((key: key, value: value, change: change));
    }
  }

  @override
  Future<String?> read(String key) async => _copy[key];

  @override
  Future<void> write(String key, String value) async => _change(key, value);

  /// When true, every delete throws, as a store that fails does.
  bool failDeletes = false;

  @override
  Future<void> delete(String key) async {
    if (failDeletes) throw StateError('boom on delete $key');
    _change(key, null);
  }

  @override
  Future<void> deleteAll() async {
    for (final key in List.of(_copy.keys)) {
      _change(key, null);
    }
  }
}

/// ISecureStorage that lets the jwtToken write succeed but throws on
/// the refresh_token write — used to exercise the rollback path in
/// `_performRefresh`. Read/delete behave normally so the rollback can
/// actually restore values.
class _RefreshWriteFailsSecureStorage implements ISecureStorage {
  final Map<String, String> _store = {};
  bool _jwtWriteSeen = false;

  Future<void> seed({required String jwt, required String refresh}) async {
    _store[SecureStorageKeys.jwtToken.key] = jwt;
    _store[SecureStorageKeys.refreshToken.key] = refresh;
  }

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    if (key == SecureStorageKeys.jwtToken.key) {
      _jwtWriteSeen = true;
      _store[key] = value;
      return;
    }
    if (key == SecureStorageKeys.refreshToken.key && _jwtWriteSeen) {
      throw StateError('refresh_token write torn after id_token landed');
    }
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> deleteAll() async => _store.clear();
}

/// Captures the Authorization header and the loop-prevention marker on
/// any incoming request, then resolves it with 200. Used to short-circuit
/// the retry's `_dio.fetch(retryOptions)` so the assertions can verify
/// what bearer the retry used and whether the marker was stamped.
class _CapturingSuccessStub extends Interceptor {
  String? lastAuthorization;
  bool lastRetryMarker = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastAuthorization = options.headers['Authorization'] as String?;
    // Marker is stored in a private Expando on RequestOptions; the
    // interceptor exposes a test-only reader so we can pin the stamp.
    lastRetryMarker = TokenRefreshInterceptor.debugIsMarkedAsRetried(options);
    handler.resolve(Response(requestOptions: options, statusCode: 200, data: '{"ok":true}'));
  }
}

/// Answers every request with 401 the way a server response does: the rejection runs the error
/// interceptors, so the 401 reaches [TokenRefreshInterceptor.onError]. Records each Authorization header.
class _UnauthorizedServerStub extends Interceptor {
  final authorizations = <String?>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    authorizations.add(options.headers['Authorization'] as String?);
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: 401),
      ),
      true,
    );
  }
}

/// Answers every request with [body], status 200 and a JSON content type. Unlike a stub interceptor's response, the
/// body goes through the transformer of the Dio that sent the request.
class _JsonBodyAdapter implements HttpClientAdapter {
  _JsonBodyAdapter(this.body);

  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// Interceptor that stubs responses or errors before any real HTTP call.
class _StubInterceptor extends Interceptor {
  int? _errorStatusCode;
  String? _errorData;
  String? _successData;
  int _successStatusCode = 200;

  void stubError({required int statusCode, String data = ''}) {
    _errorStatusCode = statusCode;
    _errorData = data;
    _successData = null;
  }

  void stubSuccess({required String data, int statusCode = 200}) {
    _successData = data;
    _successStatusCode = statusCode;
    _errorStatusCode = null;
    _errorData = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_errorStatusCode != null) {
      // true runs the error interceptors, as a server response does. Without it the error skips every onError,
      // so the pass-through tests would never reach TokenRefreshInterceptor.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: _errorStatusCode!, data: _errorData ?? ''),
        ),
        true,
      );
      return;
    }
    if (_successData != null) {
      handler.resolve(Response(requestOptions: options, data: _successData!, statusCode: _successStatusCode));
      return;
    }
    handler.next(options);
  }
}

/// Test handler to capture error interceptor behavior.
class _TestErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  bool rejectCalled = false;
  bool resolveCalled = false;
  DioException? nextError;
  DioException? rejectedError;

  @override
  void next(DioException err) {
    nextCalled = true;
    nextError = err;
  }

  @override
  void reject(DioException err, [bool callFollowingErrorInterceptor = false]) {
    rejectCalled = true;
    rejectedError = err;
  }

  @override
  void resolve(Response response) {
    resolveCalled = true;
  }
}

/// A [TokenRotation] that answers every rotation with [result], once [whileRotating] has run, and records the refresh
/// token of each call in [sent].
class _FakeRotation implements TokenRotation {
  _FakeRotation(this.result, {this.whileRotating});

  final TokenRotationResult result;
  final Future<void> Function()? whileRotating;
  final sent = <String>[];

  @override
  Future<TokenRotationResult> rotate(String refreshToken) async {
    sent.add(refreshToken);
    await whileRotating?.call();
    return result;
  }
}

/// An [_InterleavingSecureStorage] that records every key it reads, writes or deletes in [touched], and throws on the
/// write of [failWriteOf].
class _KeyRecordingSecureStorage extends _InterleavingSecureStorage {
  final touched = <String>{};
  String? failWriteOf;

  @override
  Future<String?> read(String key) {
    touched.add(key);
    return super.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    touched.add(key);
    if (key == failWriteOf) throw StateError('boom on write $key');
    await super.write(key, value);
  }

  @override
  Future<void> delete(String key) {
    touched.add(key);
    return super.delete(key);
  }
}

/// The browser's channel between the [ISessionEndSignal]s of the app's tabs: an end that one tab tells reaches every
/// other tab when [_TabSessionEndSignal.deliver] runs there.
class _SessionEndChannel {
  final _tabs = <_TabSessionEndSignal>[];

  /// The end of the channel of the tab whose copy of localStorage is [storage], whose changes are its store changes.
  _TabSessionEndSignal openTab({_TabStorage? storage}) {
    final tab = _TabSessionEndSignal._(this, storage);
    _tabs.add(tab);
    return tab;
  }
}

/// A browser tab's end of [_SessionEndChannel].
class _TabSessionEndSignal implements ISessionEndSignal {
  _TabSessionEndSignal._(this._channel, this._storage);

  final _SessionEndChannel _channel;
  final _TabStorage? _storage;
  final _endedElsewhere = StreamController<DateTime>.broadcast(sync: true);
  final _undelivered = <DateTime>[];

  @override
  void notifyEnded() => notifyEndedAt(DateTime.now());

  /// Tells the other tabs that this tab began to end the session at [at].
  void notifyEndedAt(DateTime at) {
    for (final tab in _channel._tabs) {
      if (!identical(tab, this)) tab._undelivered.add(at);
    }
  }

  /// Delivers the ends the other tabs told since the last delivery, and waits until this tab has acted on them.
  Future<void> deliver() async {
    final ends = List.of(_undelivered);
    _undelivered.clear();
    ends.forEach(_endedElsewhere.add);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Stream<DateTime> get endedElsewhere => _endedElsewhere.stream;

  @override
  Stream<void> get storeChanges => _storage?.received.map((_) {}) ?? const Stream.empty();

  @override
  void dispose() {}
}

/// Lets the take-back of a tab act on the changes its copy has just received.
Future<void> _settleTakeBack() => Future<void>.delayed(Duration.zero);

/// Collects the lines logged at [level] until the test ends.
List<String> _recordLogs(Level level) {
  final lines = <String>[];
  void record(OutputEvent event) {
    if (event.level == level) lines.addAll(event.lines);
  }

  Logger.addOutputListener(record);
  addTearDown(() => Logger.removeOutputListener(record));
  return lines;
}

/// Ends the session of this tab, as a logout does, without deleting anything.
void _wipeTheSession() => unawaited(SessionGeneration.wipe(() async {}));

/// [ISecureStorage] over a tab's storage that ends the session when [key] is read for the [readNumber]th time.
class _WipeOnReadStorage implements ISecureStorage {
  _WipeOnReadStorage(this._inner, this._key, {required this.readNumber});

  final ISecureStorage _inner;
  final String _key;
  final int readNumber;
  int _reads = 0;

  @override
  Future<String?> read(String key) async {
    final value = await _inner.read(key);
    if (key == _key && ++_reads == readNumber) _wipeTheSession();
    return value;
  }

  @override
  Future<void> write(String key, String value) => _inner.write(key, value);

  @override
  Future<void> delete(String key) => _inner.delete(key);

  @override
  Future<void> deleteAll() => _inner.deleteAll();
}

/// The stored session without the hand-over stamp of the token refresh lock.
Map<String, String> _tokensIn(_SharedLocalStorage localStorage) =>
    Map.of(localStorage.values)..remove(_TabStampCopy.key);

/// A browser tab's [TokenRefreshInterceptor] under test, and what its requests were sent again with.
class _TabUnderTest {
  _TabUnderTest(this.interceptor, this.retries);

  final TokenRefreshInterceptor interceptor;
  final _CapturingSuccessStub retries;
  final handler = _TestErrorHandler();

  /// A request this tab sent with `old-jwt` gets a 401.
  Future<void> unauthorized() {
    final requestOptions = _sentRequest('/api/users', headers: {'Authorization': 'Bearer old-jwt'});
    return interceptor.onError(
      DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      ),
      handler,
    );
  }
}

/// The Web Lock of one name and the IndexedDB hand-over record that the browser tabs share.
class _BrowserLock {
  Future<void> _tail = Future<void>.value();
  HandOver? _record;

  /// The token refresh lock of the tab that reads and writes [storage]. With [catchUpOnGrant], the tab's copy of
  /// localStorage takes the other tabs' changes before the grant, as when the browser delivers them first; without it
  /// they come only when the test delivers them, from [onGranted] for one. With [refuse], the lock is never granted,
  /// as when the page has no Web Locks API.
  ITokenRefreshLock openTab(
    _TabStorage storage, {
    bool catchUpOnGrant = true,
    void Function()? onGranted,
    Duration catchUpLimit = HandOverTokenRefreshLock.defaultCatchUpLimit,
    bool refuse = false,
  }) => HandOverTokenRefreshLock(
    mutex: _TabMutex(this, storage, catchUpOnGrant: catchUpOnGrant, onGranted: onGranted, refuse: refuse),
    record: _SharedHandOverRecord(this),
    copy: _TabStampCopy(storage),
    catchUpLimit: catchUpLimit,
  );
}

/// A tab's view of the Web Lock of [_BrowserLock]: holders run one at a time, in the order they asked.
class _TabMutex implements CrossTabMutex {
  _TabMutex(this._lock, this._storage, {required this.catchUpOnGrant, this.onGranted, required this.refuse});

  final _BrowserLock _lock;
  final _TabStorage _storage;
  final bool catchUpOnGrant;
  final void Function()? onGranted;
  final bool refuse;

  @override
  Future<T> run<T>(Future<T> Function() body) {
    if (refuse) return Future.error(StateError('navigator.locks is not available'));
    final previous = _lock._tail;
    final released = Completer<void>();
    _lock._tail = released.future;
    return previous.then((_) async {
      if (catchUpOnGrant) _storage.receive();
      onGranted?.call();
      try {
        return await body();
      } finally {
        released.complete();
      }
    });
  }
}

/// The IndexedDB hand-over record of [_BrowserLock]: every tab reads what was committed last.
class _SharedHandOverRecord implements HandOverRecord {
  _SharedHandOverRecord(this._lock);

  final _BrowserLock _lock;

  @override
  Future<HandOver?> read() async => _lock._record;

  @override
  Future<void> write(HandOver handOver) async => _lock._record = handOver;
}

/// The hand-over stamp in a [_TabStorage], next to the tokens, as in the tab's copy of localStorage.
class _TabStampCopy implements HandOverStampCopy {
  _TabStampCopy(this._storage);

  static const key = 'tokenRefreshHandOver';

  final _TabStorage _storage;

  @override
  String? read() => _storage.readNow(key);

  @override
  void write(String stamp) => _storage.writeNow(key, stamp);

  @override
  Stream<void> get changes => _storage.received.where((changed) => changed == key);

  @override
  void dispose() {}
}

/// A token server that accepts each refresh token once, as Keycloak with "Revoke Refresh Token" and "Refresh Token Max
/// Reuse" 0 does: a spent one is refused. Without [rotatesRefreshTokens] it answers only a new JWT, and accepts the
/// same refresh token again. Shared by the tabs' interceptors as their rotation.
class _OneTimeRefreshServer implements TokenRotation {
  _OneTimeRefreshServer({this.rotatesRefreshTokens = true});

  final bool rotatesRefreshTokens;
  final sent = <String>[];
  final _spent = <String>{};

  @override
  Future<TokenRotationResult> rotate(String refreshToken) async {
    sent.add(refreshToken);
    final answer = sent.length;
    // Unless the refreshes take turns, both tabs have read the stored refresh token before either stores.
    await Future<void>.delayed(Duration.zero);
    if (!rotatesRefreshTokens) return TokensRotated(accessToken: 'jwt-$answer');
    if (!_spent.add(refreshToken)) return const RotationRefused();
    return TokensRotated(accessToken: 'jwt-$answer', refreshToken: 'refresh-$answer');
  }
}

/// An identity provider whose token endpoint accepts each refresh token once, shared by the tabs' OIDC clients.
class _OneTimeOidcProvider {
  _OneTimeOidcProvider(this.expiresAt);

  final DateTime expiresAt;
  final grants = <String>[];
  final _spent = <String>{};

  Future<TokenRotationResult> refresh(String refreshToken) async {
    grants.add(refreshToken);
    final answer = grants.length;
    await Future<void>.delayed(Duration.zero);
    if (!_spent.add(refreshToken)) return const RotationRefused();
    return TokensRotated(
      accessToken: 'access-$answer',
      refreshToken: 'refresh-$answer',
      oidcIdToken: 'id-token-$answer',
      accessTokenExpiresAt: expiresAt,
    );
  }
}

/// A tab's [IOidcClient], which refreshes at [_OneTimeOidcProvider] and does nothing else.
class _OidcClientOf implements IOidcClient {
  _OidcClientOf(this._provider);

  final _OneTimeOidcProvider _provider;

  @override
  Future<TokenRotationResult> refresh({
    required String refreshToken,
    required String idToken,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  }) => _provider.refresh(refreshToken);

  @override
  Future<OidcSignInOutcome> signIn({String? webReturnPath, required String browserDoneMessage}) =>
      throw UnimplementedError();

  @override
  Future<OidcSignInOutcome?> completePendingSignIn() => throw UnimplementedError();

  @override
  Future<OidcLogoutOutcome> endProviderSession({String? idTokenHint}) => throw UnimplementedError();
}
