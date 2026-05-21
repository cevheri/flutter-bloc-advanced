import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils.dart';

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
/// key so concurrent-refresh coalescing can be asserted.
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

void main() {
  late Dio dio;
  late _MemorySecureStorage secureStorage;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() async {
    secureStorage = _MemorySecureStorage();
    dio = Dio(BaseOptions(baseUrl: 'https://test.api', responseType: ResponseType.plain));
  });

  tearDown(() async {
    dio.close();
    await TestUtils().tearDownUnitTest();
  });

  group('TokenRefreshInterceptor', () {
    test('should extend QueuedInterceptor', () {
      final interceptor = TokenRefreshInterceptor(dio: dio);
      expect(interceptor, isA<QueuedInterceptor>());
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

  group('TokenRefreshInterceptor - 401 with no refresh token', () {
    test('should call onSessionExpired when no refresh token is stored', () async {
      var sessionExpiredCalled = false;
      final interceptor = TokenRefreshInterceptor(dio: dio, onSessionExpired: () => sessionExpiredCalled = true);
      final handler = _TestErrorHandler();
      final requestOptions = RequestOptions(path: '/api/users');

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
      final requestOptions = RequestOptions(path: '/api/users');

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
      final requestOptions = RequestOptions(path: '/api/users');

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
      // Baseline the counter — earlier setup or other code paths may
      // have read the key — so we assert the DELTA introduced by the
      // three concurrent onError calls below, not the absolute count.
      final baseline = secureStorage.refreshTokenReadCount;

      final interceptor = TokenRefreshInterceptor(dio: dio, secureStorage: secureStorage);
      DioException makeErr() {
        final ro = RequestOptions(path: '/api/users');
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

      // Without coalescing this would be 3 — one refreshToken read per
      // concurrent 401. With the in-flight Future shared, all three
      // queued callers await the same refresh and the secure store is
      // read exactly once.
      expect(
        secureStorage.refreshTokenReadCount - baseline,
        1,
        reason: 'concurrent 401s should share a single refresh attempt',
      );
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
      final ro = RequestOptions(
        path: '/api/users',
        headers: {'Authorization': 'Bearer SOME_JWT'},
        extra: {'_tokenRefresh_retried': true},
      );
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
      final ro = RequestOptions(path: '/api/users', headers: {'Authorization': 'Bearer OLD_JWT'});
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

      final interceptor = TokenRefreshInterceptor(dio: dio, secureStorage: secureStorage);
      final requestOptions = RequestOptions(path: '/api/users', headers: {'Authorization': 'Bearer OLD_JWT'});
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
    });

    test('clears in-flight Future so a later 401 starts a fresh refresh', () async {
      await secureStorage.write(SecureStorageKeys.refreshToken.key, 'valid-refresh-token');
      final interceptor = TokenRefreshInterceptor(dio: dio, secureStorage: secureStorage);
      DioException makeErr() {
        final ro = RequestOptions(path: '/api/users');
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
      final requestOptions = RequestOptions(path: '/api/users');

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

      final requestOptions = RequestOptions(path: '/api/users', headers: {'Authorization': 'Bearer old-jwt'});
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

      final requestOptions = RequestOptions(path: '/api/users');
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

      final requestOptions = RequestOptions(path: '/api/users');
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

      final requestOptions = RequestOptions(path: '/api/users');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      await interceptor.onError(error, _TestErrorHandler());

      expect(logoutCount, 1);
      expect(await secureStorage.read(SecureStorageKeys.jwtToken.key), 'old-jwt');
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

      final requestOptions = RequestOptions(path: '/api/users');
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
  bool? lastRetryMarker;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastAuthorization = options.headers['Authorization'] as String?;
    lastRetryMarker = options.extra['_tokenRefresh_retried'] as bool?;
    handler.resolve(Response(requestOptions: options, statusCode: 200, data: '{"ok":true}'));
  }
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
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: _errorStatusCode!, data: _errorData ?? ''),
        ),
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
  void reject(DioException err) {
    rejectCalled = true;
  }

  @override
  void resolve(Response response) {
    resolveCalled = true;
  }
}
