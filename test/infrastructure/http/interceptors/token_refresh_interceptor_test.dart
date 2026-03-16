import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../test_utils.dart';

void main() {
  late Dio dio;
  late AppLocalStorage localStorage;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localStorage = AppLocalStorage();
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
      await localStorage.save(StorageKeys.refreshToken.name, '');

      var sessionExpiredCalled = false;
      final interceptor = TokenRefreshInterceptor(dio: dio, onSessionExpired: () => sessionExpiredCalled = true);
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
      await localStorage.save(StorageKeys.refreshToken.name, 'valid-refresh-token');
      await localStorage.save(StorageKeys.jwtToken.name, 'old-jwt-token');

      var sessionExpiredCalled = false;
      final interceptor = TokenRefreshInterceptor(dio: dio, onSessionExpired: () => sessionExpiredCalled = true);
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
