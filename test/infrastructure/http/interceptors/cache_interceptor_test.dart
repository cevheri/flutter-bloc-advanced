import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/cache_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCacheStorage extends Mock implements ICacheStorage {}

void main() {
  late CacheInterceptor interceptor;
  late MockCacheStorage mockStorage;

  setUpAll(() {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  });

  setUp(() {
    mockStorage = MockCacheStorage();
    interceptor = CacheInterceptor(storage: mockStorage);
  });

  group('CacheInterceptor', () {
    group('cache key generation', () {
      test('should generate key from method and URI', () async {
        when(() => mockStorage.read(any())).thenAnswer((_) async => null);

        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheFirst},
        );

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        // The cache key is GET_<full URI>. Since cacheFirst checks cache first,
        // and we return null, it falls through to network.
        verify(() => mockStorage.read('GET_${options.uri}')).called(1);
      });

      test('should include query parameters in cache key', () async {
        when(() => mockStorage.read(any())).thenAnswer((_) async => null);

        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          queryParameters: {'page': 1, 'limit': 10},
          extra: {'cachePolicy': CachePolicy.cacheFirst},
        );

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        final expectedKey = 'GET_${options.uri}';
        verify(() => mockStorage.read(expectedKey)).called(1);
      });
    });

    group('onRequest — non-GET requests', () {
      test('should pass through POST requests without caching', () async {
        final options = RequestOptions(path: '/api/users', method: 'POST');

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.resolveCalled, isFalse);
        verifyNever(() => mockStorage.read(any()));
      });

      test('should pass through PUT requests without caching', () async {
        final options = RequestOptions(path: '/api/users', method: 'PUT');

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.read(any()));
      });

      test('should pass through DELETE requests without caching', () async {
        final options = RequestOptions(path: '/api/users', method: 'DELETE');

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.read(any()));
      });

      test('should pass through PATCH requests without caching', () async {
        final options = RequestOptions(path: '/api/users', method: 'PATCH');

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.read(any()));
      });
    });

    group('onRequest — CachePolicy.networkFirst', () {
      test('should proceed to network (default policy)', () async {
        final options = RequestOptions(path: '/api/users', method: 'GET');

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.resolveCalled, isFalse);
      });

      test('should proceed to network when explicitly set', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          extra: {'cachePolicy': CachePolicy.networkFirst},
        );

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
      });
    });

    group('onRequest — CachePolicy.networkOnly', () {
      test('should proceed to network without checking cache', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          extra: {'cachePolicy': CachePolicy.networkOnly},
        );

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.read(any()));
      });
    });

    group('onRequest — CachePolicy.cacheOnly', () {
      test('should serve from cache when entry exists', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheOnly},
        );

        final cacheEntry = CacheEntry(key: 'GET_${options.uri}', data: '{"users": []}', createdAt: DateTime.now());
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer((_) async => cacheEntry);

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.resolveCalled, isTrue);
        expect(handler.resolvedResponse!.data, '{"users": []}');
        expect(handler.resolvedResponse!.statusCode, 200);
        expect(handler.resolvedResponse!.headers.value('x-cache'), 'hit');
      });

      test('should reject when no cache entry exists', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheOnly},
        );

        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer((_) async => null);

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.rejectCalled, isTrue);
        expect(handler.rejectedError!.message, 'No cached data available');
      });
    });

    group('onRequest — CachePolicy.cacheFirst', () {
      test('should serve from cache when valid entry exists', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheFirst},
        );

        final cacheEntry = CacheEntry(
          key: 'GET_${options.uri}',
          data: '{"cached": true}',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer((_) async => cacheEntry);

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.resolveCalled, isTrue);
        expect(handler.resolvedResponse!.data, '{"cached": true}');
        expect(handler.resolvedResponse!.headers.value('x-cache'), 'hit');
      });

      test('should fall through to network when cache miss', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheFirst},
        );

        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer((_) async => null);

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
      });

      test('should fall through to network when cache entry is expired', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheFirst},
        );

        final expiredEntry = CacheEntry(
          key: 'GET_${options.uri}',
          data: '{"stale": true}',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer((_) async => expiredEntry);

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        // Expired entry is not valid, so it falls through to network
        expect(handler.nextCalled, isTrue);
      });
    });

    group('onResponse — caching successful responses', () {
      test('should cache successful GET response with networkFirst policy', () async {
        when(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl'))).thenAnswer((_) async {});

        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkFirst},
        );
        final response = Response(requestOptions: options, statusCode: 200, data: '{"users": []}');

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
        verify(
          () => mockStorage.write('GET_${options.uri}', '{"users": []}', ttl: const Duration(minutes: 5)),
        ).called(1);
      });

      test('should not cache response with networkOnly policy', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkOnly},
        );
        final response = Response(requestOptions: options, statusCode: 200, data: '{"users": []}');

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl')));
      });

      test('should not cache non-GET responses', () async {
        final options = RequestOptions(path: '/api/users', method: 'POST', baseUrl: 'https://example.com');
        final response = Response(requestOptions: options, statusCode: 201, data: '{"id": 1}');

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl')));
      });

      test('should not cache error responses (status >= 300)', () async {
        final options = RequestOptions(path: '/api/users', method: 'GET', baseUrl: 'https://example.com');
        final response = Response(requestOptions: options, statusCode: 302, data: 'redirect');

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl')));
      });

      test('should not cache responses with null data', () async {
        final options = RequestOptions(path: '/api/users', method: 'GET', baseUrl: 'https://example.com');
        final response = Response<dynamic>(requestOptions: options, statusCode: 200, data: null);

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl')));
      });

      test('should use custom TTL when provided', () async {
        when(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl'))).thenAnswer((_) async {});

        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkFirst, 'cacheTtl': const Duration(minutes: 30)},
        );
        final response = Response(requestOptions: options, statusCode: 200, data: '{"users": []}');

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);

        verify(
          () => mockStorage.write('GET_${options.uri}', '{"users": []}', ttl: const Duration(minutes: 30)),
        ).called(1);
      });

      test('should cache with cacheFirst policy', () async {
        when(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl'))).thenAnswer((_) async {});

        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheFirst},
        );
        final response = Response(requestOptions: options, statusCode: 200, data: '{"users": []}');

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);

        verify(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl'))).called(1);
      });
    });

    group('onError — fallback to cache', () {
      test('should serve stale cache on network error with networkFirst policy', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkFirst},
        );

        final cacheEntry = CacheEntry(
          key: 'GET_${options.uri}',
          data: '{"stale_data": true}',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer((_) async => cacheEntry);

        final err = DioException(requestOptions: options, type: DioExceptionType.connectionError);

        final handler = _TestErrorHandler();
        await interceptor.onError(err, handler);

        expect(handler.resolveCalled, isTrue);
        expect(handler.resolvedResponse!.data, '{"stale_data": true}');
        expect(handler.resolvedResponse!.headers.value('x-cache'), 'stale');
      });

      test('should serve stale cache on network error with cacheFirst policy', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheFirst},
        );

        final cacheEntry = CacheEntry(key: 'GET_${options.uri}', data: '{"fallback": true}', createdAt: DateTime.now());
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer((_) async => cacheEntry);

        final err = DioException(requestOptions: options, type: DioExceptionType.connectionError);

        final handler = _TestErrorHandler();
        await interceptor.onError(err, handler);

        expect(handler.resolveCalled, isTrue);
        expect(handler.resolvedResponse!.data, '{"fallback": true}');
      });

      test('should pass error through when no cache available for networkFirst', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkFirst},
        );

        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer((_) async => null);

        final err = DioException(requestOptions: options, type: DioExceptionType.connectionError);

        final handler = _TestErrorHandler();
        await interceptor.onError(err, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.resolveCalled, isFalse);
      });

      test('should pass error through for networkOnly policy without cache fallback', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkOnly},
        );

        final err = DioException(requestOptions: options, type: DioExceptionType.connectionError);

        final handler = _TestErrorHandler();
        await interceptor.onError(err, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.read(any()));
      });

      test('should pass error through for non-GET requests', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'POST',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkFirst},
        );

        final err = DioException(requestOptions: options, type: DioExceptionType.connectionError);

        final handler = _TestErrorHandler();
        await interceptor.onError(err, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.read(any()));
      });
    });

    group('default policy', () {
      test('should default to networkFirst when no policy specified', () async {
        final options = RequestOptions(path: '/api/users', method: 'GET', baseUrl: 'https://example.com');

        // Default is networkFirst, so onRequest should pass through to network
        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
      });

      test('should default to networkFirst when extra has non-CachePolicy value', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': 'invalid'},
        );

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
      });
    });

    group('default TTL', () {
      test('should use 5 minutes as default TTL', () async {
        when(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl'))).thenAnswer((_) async {});

        final options = RequestOptions(path: '/api/users', method: 'GET', baseUrl: 'https://example.com');
        final response = Response(requestOptions: options, statusCode: 200, data: 'data');

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);

        verify(() => mockStorage.write(any(), any(), ttl: const Duration(minutes: 5))).called(1);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Test handler implementations
// ---------------------------------------------------------------------------

class _TestRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  bool resolveCalled = false;
  bool rejectCalled = false;
  Response? resolvedResponse;
  DioException? rejectedError;

  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
  }

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {
    resolveCalled = true;
    resolvedResponse = response;
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    rejectCalled = true;
    rejectedError = error;
  }
}

class _TestResponseHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;
  bool resolveCalled = false;
  Response? resolvedResponse;

  @override
  void next(Response response) {
    nextCalled = true;
  }

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {
    resolveCalled = true;
    resolvedResponse = response;
  }
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  bool resolveCalled = false;
  Response? resolvedResponse;

  @override
  void next(DioException error) {
    nextCalled = true;
  }

  @override
  void resolve(Response response) {
    resolveCalled = true;
    resolvedResponse = response;
  }
}
