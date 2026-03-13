import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

/// Interceptor that stubs responses before any real HTTP call.
class _StubInterceptor extends Interceptor {
  Response<String>? _successResponse;
  DioException? _dioError;

  void stubSuccess({required String data, int statusCode = 200}) {
    _successResponse = Response(requestOptions: RequestOptions(), data: data, statusCode: statusCode);
    _dioError = null;
  }

  void stubDioError(DioExceptionType type, {String? message, int? statusCode, String? data}) {
    _successResponse = null;
    final requestOptions = RequestOptions();
    _dioError = DioException(
      requestOptions: requestOptions,
      type: type,
      message: message,
      response: statusCode != null
          ? Response(requestOptions: requestOptions, statusCode: statusCode, data: data ?? '')
          : null,
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_dioError != null) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: _dioError!.type,
          message: _dioError!.message,
          error: _dioError!.error,
          response: _dioError!.response != null
              ? Response(
                  requestOptions: options,
                  statusCode: _dioError!.response!.statusCode,
                  data: _dioError!.response!.data,
                )
              : null,
        ),
      );
      return;
    }
    if (_successResponse != null) {
      handler.resolve(
        Response(requestOptions: options, data: _successResponse!.data, statusCode: _successResponse!.statusCode),
      );
      return;
    }
    handler.next(options);
  }
}

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    ApiClient.reset();
    await TestUtils().tearDownUnitTest();
  });

  group('Api Exceptions', () {
    test('given FetchDataException when created then should return message', () {
      final exception = FetchDataException('Test Fetch Data Exception');
      expect(exception.toString(), equals('Error During Communication: Test Fetch Data Exception'));
    });
    test('given BadRequestException when created then should return message', () {
      final exception = BadRequestException('Test Bad Request');
      expect(exception.toString(), equals('Invalid Request: Test Bad Request'));
    });
    test('given UnauthorizedException when created then should return message', () {
      final exception = UnauthorizedException('Test access denied');
      expect(exception.toString(), equals('Unauthorized: Test access denied'));
    });
    test('given InvalidInputException when created then should return message', () {
      final exception = InvalidInputException('Test invalid data');
      expect(exception.toString(), equals('Invalid Input: Test invalid data'));
    });
    test('given ApiBusinessException when created then should return message', () {
      final exception = ApiBusinessException('Test Business Exception');
      expect(exception.toString(), equals('Api Business Exception: Test Business Exception'));
    });
  });

  group('ApiClient Tests', () {
    late _StubInterceptor stub;

    setUp(() {
      ProfileConstants.setEnvironment(Environment.prod);
      stub = _StubInterceptor();
      final testDio = Dio(BaseOptions(baseUrl: 'https://test.api', responseType: ResponseType.plain));
      testDio.interceptors.add(stub);
      ApiClient.setTestInstance(testDio);
    });

    tearDown(() {
      ApiClient.reset();
    });

    group('HTTP Requests', () {
      test('given valid data when post request is made then should return success response', () async {
        stub.stubSuccess(data: '{"success": true}', statusCode: 200);
        final response = await ApiClient.post('/test', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given socket exception when post request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed');
        await expectLater(
          ApiClient.post('/test', {'data': 'test'}),
          throwsA(
            allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('No Internet connection'))]),
          ),
        );
      });

      test('given timeout when post request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.connectionTimeout, message: 'Timeout');
        await expectLater(
          ApiClient.post('/test', {'data': 'test'}),
          throwsA(allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('TimeoutException'))])),
        );
      });

      test('given valid data when get request is made then should return success 200', () async {
        stub.stubSuccess(data: '{"success": true}', statusCode: 200);
        final response = await ApiClient.get('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given connection error when get request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed');
        await expectLater(
          ApiClient.get('/test'),
          throwsA(
            allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('No Internet connection'))]),
          ),
        );
      });

      test('given 401 response when get request is made then should throw UnauthorizedException', () async {
        stub.stubDioError(DioExceptionType.badResponse, statusCode: 401, data: 'Unauthorized');
        await expectLater(
          ApiClient.get('/test'),
          throwsA(allOf([isA<UnauthorizedException>(), predicate((e) => e.toString().contains('Unauthorized'))])),
        );
      });

      test('given timeout when get request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.receiveTimeout, message: 'Timeout');
        await expectLater(
          ApiClient.get('/test'),
          throwsA(allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('TimeoutException'))])),
        );
      });

      test('given valid data when put request is made then should return success 200', () async {
        stub.stubSuccess(data: '{"success": true}', statusCode: 200);
        final response = await ApiClient.put('/test', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given connection error when put request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed');
        await expectLater(ApiClient.put('/test', {'data': 'test'}), throwsA(isA<FetchDataException>()));
      });

      test('given timeout when put request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.sendTimeout, message: 'Timeout');
        await expectLater(
          ApiClient.put('/test', {'data': 'test'}),
          throwsA(allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('TimeoutException'))])),
        );
      });

      group('PATCH', () {
        test('given valid data when patch request is made then should return success 200', () async {
          stub.stubSuccess(data: '{"success": true}', statusCode: 200);
          final response = await ApiClient.patch('/test', {'data': 'test'});
          expect(response.statusCode, lessThan(300));
        });

        test('given connection error when patch request is made then should throw FetchDataException', () async {
          stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed');
          await expectLater(ApiClient.patch('/test', {'data': 'test'}), throwsA(isA<FetchDataException>()));
        });

        test('given timeout when patch request is made then should throw FetchDataException', () async {
          stub.stubDioError(DioExceptionType.receiveTimeout, message: 'Timeout');
          await expectLater(
            ApiClient.patch('/test', {'data': 'test'}),
            throwsA(allOf([isA<FetchDataException>(), predicate((e) => e.toString().contains('TimeoutException'))])),
          );
        });
      });

      test('given valid data when delete request is made then should return success 204', () async {
        stub.stubSuccess(data: '{"success": true}', statusCode: 204);
        final response = await ApiClient.delete('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given 401 when delete request is made then should throw UnauthorizedException', () async {
        stub.stubDioError(DioExceptionType.badResponse, statusCode: 401, data: 'Unauthorized');
        await expectLater(
          ApiClient.delete('/test'),
          throwsA(allOf([isA<UnauthorizedException>(), predicate((e) => e.toString().contains('Unauthorized'))])),
        );
      });

      test('given connection error when delete request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed');
        await expectLater(ApiClient.delete('/test'), throwsA(isA<FetchDataException>()));
      });

      test('given timeout when delete request is made then should throw FetchDataException', () async {
        stub.stubDioError(DioExceptionType.receiveTimeout, message: 'Timeout');
        await expectLater(ApiClient.delete('/test'), throwsA(isA<FetchDataException>()));
      });

      test('given 400 when request is made then should throw BadRequestException', () async {
        stub.stubDioError(DioExceptionType.badResponse, statusCode: 400, data: 'Bad Request');
        await expectLater(
          ApiClient.post('/test', {'data': 'test'}),
          throwsA(allOf([isA<BadRequestException>(), predicate((e) => e.toString().contains('Bad Request'))])),
        );
      });
    });

    group('Mock Requests', () {
      setUp(() {
        ProfileConstants.setEnvironment(Environment.test);
        ApiClient.reset();
      });

      test('given test environment when GET request is made then should return mock data', () async {
        await TestUtils().setupAuthentication();
        final response = await ApiClient.get('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when GET request is made then should throw', () async {
        expect(() => ApiClient.get('/test'), throwsA(isA<UnauthorizedException>()));
      });

      test('given test environment when POST request is made then should return mock data', () async {
        await TestUtils().setupAuthentication();
        final response = await ApiClient.post('/test', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when POST request is made then should throw', () async {
        expect(() => ApiClient.post('/test', {'data': 'test'}), throwsA(isA<UnauthorizedException>()));
      });

      test('given test environment when PUT request is made then should return mock data', () async {
        await TestUtils().setupAuthentication();
        final response = await ApiClient.put('/test', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when PUT request is made then should throw', () async {
        expect(() => ApiClient.put('/test', {'data': 'test'}), throwsA(isA<UnauthorizedException>()));
      });

      test('given test environment when DELETE request is made then should return 204', () async {
        await TestUtils().setupAuthentication();
        final response = await ApiClient.delete('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given test environment without token when DELETE request is made then should throw', () async {
        expect(() => ApiClient.delete('/test'), throwsA(isA<UnauthorizedException>()));
      });
    });
  });

  group('ApiClient utilities', () {
    test('decodeUTF8 should handle valid UTF-8 string', () {
      const testString = 'Test String üğişçöIİÜĞŞÇÖ';
      final decoded = ApiClient.decodeUTF8(testString);
      expect(decoded, equals(testString));
    });

    test('decodeUTF8 should return original on failure', () {
      const testString = 'Simple ASCII';
      final decoded = ApiClient.decodeUTF8(testString);
      expect(decoded, equals(testString));
    });
  });
}
