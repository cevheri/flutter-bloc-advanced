import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/dev_console_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DevConsoleInterceptor interceptor;

  setUp(() {
    interceptor = DevConsoleInterceptor();
    DevConsoleStore.instance.clearAll();
  });

  tearDown(() {
    DevConsoleStore.instance.clearAll();
  });

  group('DevConsoleInterceptor', () {
    group('onRequest', () {
      test('should record a network entry in DevConsoleStore', () {
        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
          baseUrl: 'https://example.com',
          headers: {'Authorization': 'Bearer token'},
        );

        final handler = _TestRequestHandler();
        interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        final entries = DevConsoleStore.instance.networkEntries;
        expect(entries, isNotEmpty);
        expect(entries.first.method, 'GET');
        expect(entries.first.url, contains('/api/users'));
        expect(entries.first.requestHeaders, containsPair('Authorization', 'Bearer token'));
      });

      test('should set _devConsoleId in options.extra', () {
        final options = RequestOptions(path: '/api/test', method: 'POST');

        final handler = _TestRequestHandler();
        interceptor.onRequest(options, handler);

        expect(options.extra['_devConsoleId'], isNotNull);
        expect(options.extra['_devConsoleId'], isA<String>());
      });

      test('should record requestBody when present', () {
        final options = RequestOptions(path: '/api/users', method: 'POST', data: '{"name": "John"}');

        final handler = _TestRequestHandler();
        interceptor.onRequest(options, handler);

        final entries = DevConsoleStore.instance.networkEntries;
        expect(entries.first.requestBody, '{"name": "John"}');
      });

      test('should set startTime on entry', () {
        final before = DateTime.now();
        final options = RequestOptions(path: '/api/test', method: 'GET');

        final handler = _TestRequestHandler();
        interceptor.onRequest(options, handler);

        final entries = DevConsoleStore.instance.networkEntries;
        expect(entries.first.startTime.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      });

      test('should always call handler.next', () {
        final options = RequestOptions(path: '/api/test', method: 'GET');
        final handler = _TestRequestHandler();
        interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
      });
    });

    group('onResponse', () {
      test('should update network entry with response data', () {
        // First create a request entry
        final options = RequestOptions(path: '/api/users', method: 'GET', baseUrl: 'https://example.com');

        final requestHandler = _TestRequestHandler();
        interceptor.onRequest(options, requestHandler);

        // Then process response
        final response = Response(
          requestOptions: options,
          statusCode: 200,
          data: '{"users": []}',
          headers: Headers.fromMap({
            'content-type': ['application/json'],
          }),
        );

        final responseHandler = _TestResponseHandler();
        interceptor.onResponse(response, responseHandler);

        expect(responseHandler.nextCalled, isTrue);

        final entries = DevConsoleStore.instance.networkEntries;
        expect(entries.first.statusCode, 200);
        expect(entries.first.responseBody, '{"users": []}');
        expect(entries.first.endTime, isNotNull);
        expect(entries.first.isComplete, isTrue);
      });

      test('should update response headers', () {
        final options = RequestOptions(path: '/api/test', method: 'GET');
        final requestHandler = _TestRequestHandler();
        interceptor.onRequest(options, requestHandler);

        final response = Response(
          requestOptions: options,
          statusCode: 200,
          data: 'ok',
          headers: Headers.fromMap({
            'x-custom': ['value1'],
          }),
        );

        final responseHandler = _TestResponseHandler();
        interceptor.onResponse(response, responseHandler);

        final entries = DevConsoleStore.instance.networkEntries;
        expect(entries.first.responseHeaders, containsPair('x-custom', 'value1'));
      });

      test('should handle response without prior request entry gracefully', () {
        final options = RequestOptions(path: '/api/test', method: 'GET');
        // No onRequest was called, so no _devConsoleId in extra

        final response = Response(requestOptions: options, statusCode: 200, data: 'ok');
        final responseHandler = _TestResponseHandler();

        // Should not throw
        interceptor.onResponse(response, responseHandler);
        expect(responseHandler.nextCalled, isTrue);
      });

      test('should always call handler.next', () {
        final options = RequestOptions(path: '/api/test', method: 'GET');
        final response = Response(requestOptions: options, statusCode: 200, data: 'ok');
        final handler = _TestResponseHandler();

        interceptor.onResponse(response, handler);
        expect(handler.nextCalled, isTrue);
      });
    });

    group('onError', () {
      test('should update network entry with error information', () {
        final options = RequestOptions(path: '/api/users', method: 'GET', baseUrl: 'https://example.com');

        final requestHandler = _TestRequestHandler();
        interceptor.onRequest(options, requestHandler);

        final dioError = DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timed out',
        );

        final errorHandler = _TestErrorHandler();
        interceptor.onError(dioError, errorHandler);

        expect(errorHandler.nextCalled, isTrue);

        final entries = DevConsoleStore.instance.networkEntries;
        expect(entries.first.error, isNotNull);
        expect(entries.first.error, contains('connectionTimeout'));
        expect(entries.first.error, contains('Connection timed out'));
        expect(entries.first.endTime, isNotNull);
      });

      test('should update statusCode from error response', () {
        final options = RequestOptions(path: '/api/users', method: 'GET');
        final requestHandler = _TestRequestHandler();
        interceptor.onRequest(options, requestHandler);

        final errorResponse = Response(requestOptions: options, statusCode: 500, data: 'Server Error');
        final dioError = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: errorResponse,
          message: 'Internal Server Error',
        );

        final errorHandler = _TestErrorHandler();
        interceptor.onError(dioError, errorHandler);

        final entries = DevConsoleStore.instance.networkEntries;
        expect(entries.first.statusCode, 500);
        expect(entries.first.responseBody, 'Server Error');
      });

      test('should handle error with null message', () {
        final options = RequestOptions(path: '/api/test', method: 'GET');
        final requestHandler = _TestRequestHandler();
        interceptor.onRequest(options, requestHandler);

        final dioError = DioException(requestOptions: options, type: DioExceptionType.unknown);

        final errorHandler = _TestErrorHandler();
        interceptor.onError(dioError, errorHandler);

        final entries = DevConsoleStore.instance.networkEntries;
        expect(entries.first.error, contains('Unknown error'));
      });

      test('should handle error without prior request entry gracefully', () {
        final options = RequestOptions(path: '/api/test', method: 'GET');
        final dioError = DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'Failed',
        );

        final errorHandler = _TestErrorHandler();
        // Should not throw
        interceptor.onError(dioError, errorHandler);
        expect(errorHandler.nextCalled, isTrue);
      });

      test('should always call handler.next', () {
        final options = RequestOptions(path: '/api/test', method: 'GET');
        final dioError = DioException(requestOptions: options, type: DioExceptionType.cancel);
        final handler = _TestErrorHandler();

        interceptor.onError(dioError, handler);
        expect(handler.nextCalled, isTrue);
      });
    });

    group('full request lifecycle', () {
      test('should track request through success response', () {
        final options = RequestOptions(
          path: '/api/data',
          method: 'POST',
          baseUrl: 'https://api.example.com',
          data: '{"payload": true}',
        );

        // Request phase
        final requestHandler = _TestRequestHandler();
        interceptor.onRequest(options, requestHandler);

        var entries = DevConsoleStore.instance.networkEntries;
        expect(entries.length, 1);
        expect(entries.first.isComplete, isFalse);

        // Response phase
        final response = Response(requestOptions: options, statusCode: 201, data: '{"id": 123}');
        final responseHandler = _TestResponseHandler();
        interceptor.onResponse(response, responseHandler);

        entries = DevConsoleStore.instance.networkEntries;
        expect(entries.length, 1);
        expect(entries.first.isComplete, isTrue);
        expect(entries.first.statusCode, 201);
        expect(entries.first.duration, isNotNull);
      });

      test('should track request through error', () {
        final options = RequestOptions(path: '/api/data', method: 'GET', baseUrl: 'https://api.example.com');

        // Request phase
        final requestHandler = _TestRequestHandler();
        interceptor.onRequest(options, requestHandler);

        // Error phase
        final dioError = DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
          message: 'Timeout',
        );
        final errorHandler = _TestErrorHandler();
        interceptor.onError(dioError, errorHandler);

        final entries = DevConsoleStore.instance.networkEntries;
        expect(entries.length, 1);
        expect(entries.first.isComplete, isTrue);
        expect(entries.first.isError, isTrue);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Test handler implementations
// ---------------------------------------------------------------------------

class _TestRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
  }
}

class _TestResponseHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(Response response) {
    nextCalled = true;
  }
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(DioException error) {
    nextCalled = true;
  }
}
