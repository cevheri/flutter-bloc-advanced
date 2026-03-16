import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/logging_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils.dart';

void main() {
  late LoggingInterceptor interceptor;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    interceptor = LoggingInterceptor();
  });

  group('LoggingInterceptor', () {
    test('should extend Interceptor', () {
      expect(interceptor, isA<Interceptor>());
    });

    group('onRequest', () {
      test('should call handler.next to pass request through', () {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          headers: {'Authorization': 'Bearer token', 'Content-Type': 'application/json'},
        );
        final handler = _TestRequestHandler();

        interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextOptions, isNotNull);
        expect(handler.nextOptions!.path, '/api/users');
        expect(handler.nextOptions!.method, 'GET');
      });

      test('should pass through POST requests', () {
        final options = RequestOptions(path: '/api/users', method: 'POST');
        final handler = _TestRequestHandler();

        interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextOptions!.method, 'POST');
      });

      test('should pass through PUT requests', () {
        final options = RequestOptions(path: '/api/users/123', method: 'PUT');
        final handler = _TestRequestHandler();

        interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextOptions!.method, 'PUT');
      });

      test('should pass through DELETE requests', () {
        final options = RequestOptions(path: '/api/users/123', method: 'DELETE');
        final handler = _TestRequestHandler();

        interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextOptions!.method, 'DELETE');
      });

      test('should pass through PATCH requests', () {
        final options = RequestOptions(path: '/api/users/123', method: 'PATCH');
        final handler = _TestRequestHandler();

        interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextOptions!.method, 'PATCH');
      });

      test('should not reject or resolve the request', () {
        final options = RequestOptions(path: '/api/test', method: 'GET');
        final handler = _TestRequestHandler();

        interceptor.onRequest(options, handler);

        expect(handler.rejectCalled, isFalse);
        expect(handler.resolveCalled, isFalse);
      });

      test('should preserve all request options when passing through', () {
        final options = RequestOptions(
          path: '/api/data',
          method: 'POST',
          baseUrl: 'https://api.example.com',
          headers: {'Authorization': 'Bearer xyz', 'Accept': 'application/json'},
          data: '{"name":"test"}',
        );
        final handler = _TestRequestHandler();

        interceptor.onRequest(options, handler);

        expect(handler.nextOptions!.path, '/api/data');
        expect(handler.nextOptions!.method, 'POST');
        expect(handler.nextOptions!.data, '{"name":"test"}');
      });
    });

    group('onResponse', () {
      test('should call handler.next to pass response through', () {
        final requestOptions = RequestOptions(path: '/api/users', method: 'GET');
        final response = Response(requestOptions: requestOptions, statusCode: 200, data: '{"users":[]}');
        final handler = _TestResponseHandler();

        interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextResponse, isNotNull);
        expect(handler.nextResponse!.statusCode, 200);
      });

      test('should pass through 201 responses', () {
        final requestOptions = RequestOptions(path: '/api/users', method: 'POST');
        final response = Response(requestOptions: requestOptions, statusCode: 201, data: '{"id":1}');
        final handler = _TestResponseHandler();

        interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextResponse!.statusCode, 201);
      });

      test('should pass through 204 responses', () {
        final requestOptions = RequestOptions(path: '/api/users/1', method: 'DELETE');
        final response = Response(requestOptions: requestOptions, statusCode: 204, data: null);
        final handler = _TestResponseHandler();

        interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextResponse!.statusCode, 204);
      });

      test('should handle response with null data', () {
        final requestOptions = RequestOptions(path: '/api/test', method: 'GET');
        final response = Response(requestOptions: requestOptions, statusCode: 200, data: null);
        final handler = _TestResponseHandler();

        interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
      });

      test('should handle response with large data', () {
        final requestOptions = RequestOptions(path: '/api/test', method: 'GET');
        final largeData = 'x' * 10000;
        final response = Response(requestOptions: requestOptions, statusCode: 200, data: largeData);
        final handler = _TestResponseHandler();

        interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextResponse!.data, largeData);
      });

      test('should not reject the response', () {
        final requestOptions = RequestOptions(path: '/api/test', method: 'GET');
        final response = Response(requestOptions: requestOptions, statusCode: 200, data: '');
        final handler = _TestResponseHandler();

        interceptor.onResponse(response, handler);

        expect(handler.rejectCalled, isFalse);
      });
    });

    group('onError', () {
      test('should call handler.next to pass error through', () {
        final requestOptions = RequestOptions(path: '/api/users', method: 'GET');
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
          message: 'Connection refused',
        );
        final handler = _TestErrorHandler();

        interceptor.onError(error, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextError, isNotNull);
      });

      test('should pass through timeout errors', () {
        final requestOptions = RequestOptions(path: '/api/users', method: 'GET');
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timed out',
        );
        final handler = _TestErrorHandler();

        interceptor.onError(error, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextError!.type, DioExceptionType.connectionTimeout);
      });

      test('should pass through bad response errors', () {
        final requestOptions = RequestOptions(path: '/api/users', method: 'POST');
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: requestOptions, statusCode: 500, data: 'Server Error'),
          message: 'Internal Server Error',
        );
        final handler = _TestErrorHandler();

        interceptor.onError(error, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextError!.type, DioExceptionType.badResponse);
      });

      test('should handle error with null message', () {
        final requestOptions = RequestOptions(path: '/api/users', method: 'GET');
        final error = DioException(requestOptions: requestOptions, type: DioExceptionType.unknown);
        final handler = _TestErrorHandler();

        interceptor.onError(error, handler);

        expect(handler.nextCalled, isTrue);
      });

      test('should pass through cancel errors', () {
        final requestOptions = RequestOptions(path: '/api/users', method: 'GET');
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.cancel,
          message: 'Request cancelled',
        );
        final handler = _TestErrorHandler();

        interceptor.onError(error, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextError!.type, DioExceptionType.cancel);
      });

      test('should preserve request path and method in error', () {
        final requestOptions = RequestOptions(path: '/api/users/42', method: 'DELETE');
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: requestOptions, statusCode: 404),
          message: 'Not Found',
        );
        final handler = _TestErrorHandler();

        interceptor.onError(error, handler);

        expect(handler.nextError!.requestOptions.path, '/api/users/42');
        expect(handler.nextError!.requestOptions.method, 'DELETE');
      });

      test('should not resolve errors as successful responses', () {
        final requestOptions = RequestOptions(path: '/api/test', method: 'GET');
        final error = DioException(requestOptions: requestOptions, type: DioExceptionType.connectionError);
        final handler = _TestErrorHandler();

        interceptor.onError(error, handler);

        expect(handler.resolveCalled, isFalse);
        expect(handler.rejectCalled, isFalse);
        expect(handler.nextCalled, isTrue);
      });
    });

    group('integration with Dio', () {
      test('should log and pass through successful GET request', () async {
        final testDio = Dio(BaseOptions(baseUrl: 'https://test.api'));
        testDio.interceptors.addAll([interceptor, _StubResponseInterceptor()]);

        final response = await testDio.get('/api/users');

        expect(response.statusCode, 200);
        expect(response.data, '{"ok":true}');
      });

      test('should log and pass through successful POST request', () async {
        final testDio = Dio(BaseOptions(baseUrl: 'https://test.api'));
        testDio.interceptors.addAll([interceptor, _StubResponseInterceptor()]);

        final response = await testDio.post('/api/users', data: '{"name":"test"}');

        expect(response.statusCode, 200);
      });

      test('should log and pass through error response', () async {
        final testDio = Dio(BaseOptions(baseUrl: 'https://test.api'));
        testDio.interceptors.addAll([interceptor, _StubErrorInterceptor(statusCode: 500)]);

        expect(() => testDio.get('/api/users'), throwsA(isA<DioException>()));
      });
    });
  });
}

/// Test handler for request interceptor.
class _TestRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  bool rejectCalled = false;
  bool resolveCalled = false;
  RequestOptions? nextOptions;

  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
    nextOptions = requestOptions;
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    rejectCalled = true;
  }

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {
    resolveCalled = true;
  }
}

/// Test handler for response interceptor.
class _TestResponseHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;
  bool rejectCalled = false;
  Response? nextResponse;

  @override
  void next(Response response) {
    nextCalled = true;
    nextResponse = response;
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    rejectCalled = true;
  }
}

/// Test handler for error interceptor.
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

/// Stub interceptor that returns a successful response.
class _StubResponseInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(Response(requestOptions: options, data: '{"ok":true}', statusCode: 200));
  }
}

/// Stub interceptor that returns an error response.
class _StubErrorInterceptor extends Interceptor {
  final int statusCode;

  _StubErrorInterceptor({required this.statusCode});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: statusCode, data: 'Error'),
      ),
    );
  }
}
