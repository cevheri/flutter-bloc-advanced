import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';
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

  /// Applies the changes the other tabs made since the last delivery, in their order. A change older than the one this
  /// tab's copy holds for the key is skipped: the browser's copy holds the later one.
  void receive() {
    for (final change in _undelivered) {
      if ((_changeOfKey[change.key] ?? 0) > change.change) continue;
      _take(change.key, change.value, change.change);
    }
    _undelivered.clear();
  }

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

  @override
  Future<void> delete(String key) async => _change(key, null);

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

  @override
  void next(DioException err) {
    nextCalled = true;
    nextError = err;
  }

  @override
  void reject(DioException err, [bool callFollowingErrorInterceptor = false]) {
    rejectCalled = true;
  }

  @override
  void resolve(Response response) {
    resolveCalled = true;
  }
}
