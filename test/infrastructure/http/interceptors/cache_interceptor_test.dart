import 'dart:async';
import 'dart:io' show HandshakeException, HttpException, OSError, RedirectException, SocketException;

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/cache_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCacheStorage extends Mock implements ICacheStorage {}

void main() {
  late CacheInterceptor interceptor;
  late MockCacheStorage mockStorage;

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

      // The storage keeps an entry past its TTL to answer a GET that cannot reach the server; cacheOnly answers from
      // a fresh entry only, as before.
      test('should reject when the entry is past its TTL', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheOnly},
        );
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer(
          (_) async => CacheEntry(
            key: 'GET_${options.uri}',
            data: '{"users": []}',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        );

        final handler = _TestRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.resolveCalled, isFalse);
        expect(handler.rejectedError!.message, 'No cached data available');
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
        // So that the log, the dev console and the other onError handlers see the failure.
        expect(handler.rejectCallsFollowing, isTrue);
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
        verify(() => mockStorage.write('GET_${options.uri}', '{"users": []}', ttl: const Duration(minutes: 5)))
            .called(1);
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

        verify(() => mockStorage.write('GET_${options.uri}', '{"users": []}', ttl: const Duration(minutes: 30)))
            .called(1);
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

      /// A GET sent under the session generation [sentUnder], as AuthInterceptor records it.
      Response<String> responseSentUnder(int sentUnder) => Response(
        requestOptions: RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {AuthInterceptor.sessionGenerationKey: sentUnder},
        ),
        statusCode: 200,
        data: '{"users": []}',
      );

      // Regression: a GET still on its way when the session ended stored its response after the logout cleared the
      // cache, so it could answer the next user's GET that cannot reach the server.
      test('should not cache a response whose session ended while it was on its way', () async {
        when(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl'))).thenAnswer((_) async {});
        final response = responseSentUnder(SessionGeneration.current);
        await SessionGeneration.wipe(() async {});

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl')));
      });

      test('should not cache a response that arrives while the session is wiped', () async {
        when(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl'))).thenAnswer((_) async {});
        final response = responseSentUnder(SessionGeneration.current);
        final releaseWipe = Completer<void>();
        final wipe = SessionGeneration.wipe(() => releaseWipe.future);

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);
        releaseWipe.complete();
        await wipe;

        expect(handler.nextCalled, isTrue);
        verifyNever(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl')));
      });

      // Guards that the check skips only an ended session: the response of the current one is cached as before.
      test('should cache a response sent under the current session', () async {
        when(() => mockStorage.write(any(), any(), ttl: any(named: 'ttl'))).thenAnswer((_) async {});
        await SessionGeneration.wipe(() async {});
        final response = responseSentUnder(SessionGeneration.current);

        final handler = _TestResponseHandler();
        await interceptor.onResponse(response, handler);

        verify(() => mockStorage.write(any(), '{"users": []}', ttl: any(named: 'ttl'))).called(1);
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

      // A fresh cacheFirst entry is what onRequest answers as a hit; it reaches onError when ConnectivityInterceptor
      // rejected the GET before this interceptor saw it.
      test('should mark a fresh cacheFirst entry that answers a connection error as a hit', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheFirst},
        );
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer(
          (_) async => CacheEntry(
            key: 'GET_${options.uri}',
            data: '{"fresh": true}',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          ),
        );

        final handler = _TestErrorHandler();
        await interceptor.onError(
          DioException(requestOptions: options, type: DioExceptionType.connectionError),
          handler,
        );

        expect(handler.resolvedResponse!.data, '{"fresh": true}');
        expect(handler.resolvedResponse!.headers.value('x-cache'), 'hit');
      });

      // Guards that only a fresh entry is a hit: an expired one stands in for the server, as before.
      test('should mark an expired cacheFirst entry that answers a connection error as stale', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.cacheFirst},
        );
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer(
          (_) async => CacheEntry(
            key: 'GET_${options.uri}',
            data: '{"expired": true}',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        );

        final handler = _TestErrorHandler();
        await interceptor.onError(
          DioException(requestOptions: options, type: DioExceptionType.connectionError),
          handler,
        );

        expect(handler.resolvedResponse!.data, '{"expired": true}');
        expect(handler.resolvedResponse!.headers.value('x-cache'), 'stale');
      });

      // Guards the answers for a connection closed or reset after it was opened, which dio reports as unknown with the
      // dart:io error. These are the errors loopback sockets gave for such a cut (see the cut connections in
      // api_client_test.dart).
      for (final (description, error) in <(String, Object)>[
        ('a close while the body is read', const HttpException('Connection closed while receiving data')),
        ('a reset while the response is awaited', const HttpException('Connection reset by peer')),
        ('a reset as soon as the connection is accepted', const OSError('Connection reset by peer', 104)),
        ('a reset while the request is written', const SocketException('Write failed')),
      ]) {
        test('should serve stale cache after $description', () async {
          final options = RequestOptions(
            path: '/api/users',
            method: 'GET',
            baseUrl: 'https://example.com',
            extra: {'cachePolicy': CachePolicy.networkFirst},
          );

          final cacheEntry = CacheEntry(
            key: 'GET_${options.uri}',
            data: '{"stale_data": true}',
            createdAt: DateTime.now(),
          );
          when(() => mockStorage.read('GET_${options.uri}')).thenAnswer((_) async => cacheEntry);

          final err = DioException(requestOptions: options, type: DioExceptionType.unknown, error: error);

          final handler = _TestErrorHandler();
          await interceptor.onError(err, handler);

          expect(handler.resolveCalled, isTrue);
          expect(handler.resolvedResponse!.headers.value('x-cache'), 'stale');
        });
      }

      // Unlike any other HttpException, a response dart:io cannot parse included, a RedirectException does not mean a
      // lost connection: the server answered with a redirect loop, or with more redirects than dio follows.
      test('should pass a RedirectException through even when a cached entry exists', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkFirst},
        );
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer(
          (_) async => CacheEntry(key: 'GET_${options.uri}', data: '{"stale_data": true}', createdAt: DateTime.now()),
        );

        final err = DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: const RedirectException('Redirect limit exceeded', []),
        );

        final handler = _TestErrorHandler();
        await interceptor.onError(err, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.resolveCalled, isFalse);
      });

      // A pin mismatch means the connection may be intercepted, so it must fail closed, not look like being offline.
      test('should pass a certificate pin mismatch through even when a cached entry exists', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkFirst},
        );

        final cacheEntry = CacheEntry(
          key: 'GET_${options.uri}',
          data: '{"stale_data": true}',
          createdAt: DateTime.now(),
        );
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer((_) async => cacheEntry);

        // The pinned adapter's handshake failure, as dio wraps it: unknown type, no response.
        final err = DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: const CertificatePinningException('example.com', 443),
        );

        final handler = _TestErrorHandler();
        await interceptor.onError(err, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.resolveCalled, isFalse);
      });

      // A TLS failure means the connection may be intercepted or the server cannot be trusted, so it must fail
      // instead of looking like being offline. dio wraps it, like a dropped connection, as unknown without a response.
      test('should pass a TLS handshake failure through even when a cached entry exists', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkFirst},
        );
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer(
          (_) async => CacheEntry(key: 'GET_${options.uri}', data: '{"stale_data": true}', createdAt: DateTime.now()),
        );

        final err = DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: const HandshakeException('Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED)'),
        );

        final handler = _TestErrorHandler();
        await interceptor.onError(err, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.resolveCalled, isFalse);
      });

      // Only a failure to reach the server may be answered from the cache; an error nobody expected must surface.
      test('should pass any other unknown error through even when a cached entry exists', () async {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          extra: {'cachePolicy': CachePolicy.networkFirst},
        );
        when(() => mockStorage.read('GET_${options.uri}')).thenAnswer(
          (_) async => CacheEntry(key: 'GET_${options.uri}', data: '{"stale_data": true}', createdAt: DateTime.now()),
        );

        final err = DioException(requestOptions: options, type: DioExceptionType.unknown, error: StateError('bug'));

        final handler = _TestErrorHandler();
        await interceptor.onError(err, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.resolveCalled, isFalse);
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
  bool rejectCallsFollowing = false;

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
    rejectCallsFollowing = callFollowingErrorInterceptor;
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
