import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_utils.dart';

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

/// Valid bundle JSON used in fetchBundle success tests.
final _validBundleJson = jsonEncode({
  'schema': {
    'id': 'user_extended_info',
    'title': 'User Extended Info',
    'fields': [
      {'type': 'text', 'key': 'firstName', 'label': 'First Name'},
    ],
  },
  'values': {'firstName': 'Alice'},
});

void main() {
  late _StubInterceptor stub;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    stub = _StubInterceptor();
    final testDio = Dio(BaseOptions(baseUrl: 'https://test.api', responseType: ResponseType.plain));
    testDio.interceptors.add(stub);
    ApiClient.setTestInstance(testDio);
  });

  tearDown(() async {
    ApiClient.reset();
    await TestUtils().tearDownUnitTest();
  });

  group('DynamicFormRepository input validation', () {
    final repo = DynamicFormRepository();

    test('fetchSchema returns ValidationError when formId is empty', () async {
      final result = await repo.fetchSchema('');

      expect(result, isA<Failure<FormSchemaEntity>>());
      final failure = result as Failure<FormSchemaEntity>;
      expect(failure.error, isA<ValidationError>());
      expect(failure.error.message, DynamicFormRepository.formIdRequired);
    });

    test('submit returns ValidationError when action.endpoint is empty', () async {
      final result = await repo.submit(const FormSubmitAction(method: 'POST', endpoint: ''), const {});

      expect(result, isA<Failure<String?>>());
      final failure = result as Failure<String?>;
      expect(failure.error, isA<ValidationError>());
      expect(failure.error.message, DynamicFormRepository.submitEndpointRequired);
    });

    test('submit returns ValidationError when action.method is empty', () async {
      final result = await repo.submit(const FormSubmitAction(method: '', endpoint: '/leads'), const {});

      expect(result, isA<Failure<String?>>());
      final failure = result as Failure<String?>;
      expect(failure.error, isA<ValidationError>());
      expect(failure.error.message, DynamicFormRepository.submitMethodRequired);
    });
  });

  group('fetchBundle', () {
    final repo = DynamicFormRepository();

    test('returns Failure<FormBundleEntity> with ValidationError when endpoint is empty', () async {
      final result = await repo.fetchBundle('');

      expect(result, isA<Failure<FormBundleEntity>>());
      final failure = result as Failure<FormBundleEntity>;
      expect(failure.error, isA<ValidationError>());
      expect(failure.error.message, DynamicFormRepository.endpointRequired);
    });

    test('returns Success<FormBundleEntity> with correct schema.id and values on valid response', () async {
      stub.stubSuccess(data: _validBundleJson);

      final result = await repo.fetchBundle('/admin/users/42/extended');

      expect(result, isA<Success<FormBundleEntity>>());
      final success = result as Success<FormBundleEntity>;
      expect(success.data.schema.id, 'user_extended_info');
      expect(success.data.values, {'firstName': 'Alice'});
    });

    test('returns Failure<FormBundleEntity> with NetworkError on connectionTimeout', () async {
      stub.stubDioError(DioExceptionType.connectionTimeout, message: 'Timeout');

      final result = await repo.fetchBundle('/admin/users/42/extended');

      expect(result, isA<Failure<FormBundleEntity>>());
      final failure = result as Failure<FormBundleEntity>;
      expect(failure.error, isA<NetworkError>());
    });
  });
}
