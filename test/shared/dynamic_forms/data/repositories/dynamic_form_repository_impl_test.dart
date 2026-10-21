import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_env.dart';

/// Interceptor that stubs responses before any real HTTP call.
class _StubInterceptor extends Interceptor {
  Response<String>? _successResponse;
  DioException? _dioError;

  /// The URI of every request that reached the stub, so a test can tell that nothing was sent.
  final sentUris = <Uri>[];

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
    sentUris.add(options.uri);
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

/// Production chain (no MockInterceptor) with certificate pinning configured.
const _pinnedProdConfig = AppConfig(
  environment: Environment.prod,
  apiBaseUrl: 'https://api.example.test',
  certificatePins: ['test-pin'],
  idleTimeout: null,
);

/// Fails every request as the pinning adapter fails a server whose certificate matches no configured pin.
class _PinMismatchAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw const CertificatePinningException('api.example.test', 443);
  }

  @override
  void close({bool force = false}) {}
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

  late DynamicFormRepository repo;

  setUp(() {
    stub = _StubInterceptor();
    final testDio = Dio(BaseOptions(baseUrl: 'https://test.api', responseType: ResponseType.plain));
    testDio.interceptors.add(stub);
    repo = DynamicFormRepository(TestEnv.apiClient(dio: testDio));
  });

  group('DynamicFormRepository input validation', () {
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

  // A form definition comes from the server, and Dio sends a request to an absolute URL there instead of to the API,
  // so whoever can write a form could collect what the users submit, and before AuthInterceptor checked the origin,
  // their access tokens too.
  group('endpoints that leave the API', () {
    const outside = [
      'https://other.example/collect',
      'http://test.api/leads',
      '//other.example/collect',
      'other.example/collect',
      '@other.example/collect',
    ];

    for (final endpoint in outside) {
      for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
        test('submit rejects $method $endpoint and sends nothing', () async {
          stub.stubSuccess(data: '{}');

          final result = await repo.submit(FormSubmitAction(method: method, endpoint: endpoint), const {'a': 'b'});

          expect(stub.sentUris, isEmpty);
          expect(result, isA<Failure<String?>>());
          final failure = result as Failure<String?>;
          expect(failure.error, isA<ValidationError>());
          expect(failure.error.message, DynamicFormRepository.submitEndpointNotApiPath);
        });
      }

      test('fetchBundle rejects $endpoint and sends nothing', () async {
        stub.stubSuccess(data: _validBundleJson);

        final result = await repo.fetchBundle(endpoint, pathParams: '42');

        expect(stub.sentUris, isEmpty);
        expect(result, isA<Failure<FormBundleEntity>>());
        final failure = result as Failure<FormBundleEntity>;
        expect(failure.error, isA<ValidationError>());
        expect(failure.error.message, DynamicFormRepository.endpointNotApiPath);
      });
    }

    test('submit sends a relative endpoint to the API', () async {
      stub.stubSuccess(data: '{"ok":true}');

      final result = await repo.submit(const FormSubmitAction(method: 'POST', endpoint: '/leads'), const {'a': 'b'});

      expect(result, isA<Success<String?>>());
      expect(stub.sentUris.single, Uri.parse('https://test.api/leads'));
    });
  });

  group('submit', () {
    // A server-driven form chooses the keys of its fields, so the key of a password field may name no credential.
    for (final method in ['POST', 'PUT', 'PATCH']) {
      test('$method keeps the value of a sensitive key out of an error that repeats it', () async {
        stub.stubDioError(
          DioExceptionType.badResponse,
          statusCode: 400,
          data: '{"detail":"PIN S3cret!pw was used before"}',
        );

        final result = await repo.submit(
          FormSubmitAction(method: method, endpoint: '/pins'),
          const {'login': 'admin', 'pin': 'S3cret!pw'},
          sensitiveKeys: {'pin'},
        );

        final message = (result as Failure<String?>).error.message;
        expect(message, allOf(contains('PIN [REDACTED] was used before'), isNot(contains('S3cret!pw'))));
      });
    }
  });

  group('fetchBundle', () {
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

    // Regression: a certificate pin mismatch came back as a NetworkError without a code, so the screen showed the
    // exception text, host and port included, instead of a message the user can act on.
    test('returns Failure<FormBundleEntity> with AppErrorCode.networkCertInvalid on a pin mismatch', () async {
      final apiClient = ApiClient(appConfig: _pinnedProdConfig, secureStorage: FlutterSecureStorageAdapter());
      apiClient.instance.httpClientAdapter = _PinMismatchAdapter();

      final result = await DynamicFormRepository(apiClient).fetchBundle('/admin/users/extended', pathParams: '42');

      expect(result, isA<Failure<FormBundleEntity>>());
      final failure = result as Failure<FormBundleEntity>;
      expect(failure.error, isA<NetworkError>());
      expect(failure.error.code, AppErrorCode.networkCertInvalid.key);
    });
  });
}
