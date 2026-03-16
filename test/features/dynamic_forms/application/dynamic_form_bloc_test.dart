import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils.dart';

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

/// Minimal valid form schema JSON for testing.
final _validFormSchemaJson = jsonEncode({
  'id': 'test_form',
  'title': 'Test Form',
  'description': 'A test form description.',
  'fields': [
    {
      'type': 'text',
      'key': 'name',
      'label': 'Full Name',
      'required': true,
      'validators': ['minLength:2'],
    },
    {'type': 'email', 'key': 'email', 'label': 'Email', 'required': true},
    {
      'type': 'dropdown',
      'key': 'source',
      'label': 'Source',
      'options': ['Web', 'Referral'],
    },
  ],
  'submitAction': {'method': 'POST', 'endpoint': '/leads'},
  'layout': 'responsive',
});

/// Form schema JSON without submitAction (for the "no submit action" branch).
final _formSchemaNoAction = jsonEncode({
  'id': 'no_action_form',
  'title': 'No Action Form',
  'fields': [
    {'type': 'text', 'key': 'name', 'label': 'Name'},
  ],
});

/// Form schema with PUT submitAction.
final _formSchemaPutAction = jsonEncode({
  'id': 'put_form',
  'title': 'PUT Form',
  'fields': [
    {'type': 'text', 'key': 'name', 'label': 'Name'},
  ],
  'submitAction': {'method': 'PUT', 'endpoint': '/leads/1'},
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

  group('DynamicFormState', () {
    test('initial state has correct defaults', () {
      const state = DynamicFormState();
      expect(state.status, DynamicFormStatus.initial);
      expect(state.schema, isNull);
      expect(state.submitResponse, isNull);
      expect(state.error, isNull);
    });

    test('supports value equality', () {
      const state1 = DynamicFormState();
      const state2 = DynamicFormState();
      expect(state1, equals(state2));
    });

    test('copyWith replaces non-null parameters', () {
      const state = DynamicFormState();
      final updated = state.copyWith(status: DynamicFormStatus.loading);
      expect(updated.status, DynamicFormStatus.loading);
      expect(updated.schema, isNull);
    });

    test('copyWith preserves existing values when no args given', () {
      const state = DynamicFormState(status: DynamicFormStatus.loaded, error: 'something');
      final copy = state.copyWith();
      expect(copy.status, DynamicFormStatus.loaded);
      expect(copy.error, 'something');
    });

    test('props contains all fields', () {
      const state = DynamicFormState();
      expect(state.props, [DynamicFormStatus.initial, null, null, null]);
    });
  });

  group('DynamicFormEvent', () {
    group('base DynamicFormEvent', () {
      test('supports value equality', () {
        const event1 = DynamicFormEvent();
        const event2 = DynamicFormEvent();
        expect(event1, equals(event2));
      });

      test('props is empty list', () {
        const event = DynamicFormEvent();
        expect(event.props, <Object?>[]);
      });

      test('toString contains class name', () {
        const event = DynamicFormEvent();
        expect(event.toString(), contains('DynamicFormEvent'));
      });
    });

    group('DynamicFormLoadEvent', () {
      test('supports value equality with same formId', () {
        const event1 = DynamicFormLoadEvent('form_1');
        const event2 = DynamicFormLoadEvent('form_1');
        expect(event1, equals(event2));
      });

      test('is not equal when formId differs', () {
        const event1 = DynamicFormLoadEvent('form_1');
        const event2 = DynamicFormLoadEvent('form_2');
        expect(event1, isNot(equals(event2)));
      });

      test('props contains formId', () {
        const event = DynamicFormLoadEvent('form_1');
        expect(event.props, ['form_1']);
      });

      test('formId getter returns the correct value', () {
        const event = DynamicFormLoadEvent('my_form');
        expect(event.formId, 'my_form');
      });

      test('toString contains class name and formId', () {
        const event = DynamicFormLoadEvent('form_1');
        final str = event.toString();
        expect(str, contains('DynamicFormLoadEvent'));
        expect(str, contains('form_1'));
      });

      test('is a subclass of DynamicFormEvent', () {
        const event = DynamicFormLoadEvent('form_1');
        expect(event, isA<DynamicFormEvent>());
      });
    });

    group('DynamicFormSubmitEvent', () {
      test('supports value equality with same data', () {
        const event1 = DynamicFormSubmitEvent({'name': 'John'});
        const event2 = DynamicFormSubmitEvent({'name': 'John'});
        expect(event1, equals(event2));
      });

      test('is not equal when data differs', () {
        const event1 = DynamicFormSubmitEvent({'name': 'John'});
        const event2 = DynamicFormSubmitEvent({'name': 'Jane'});
        expect(event1, isNot(equals(event2)));
      });

      test('props contains data map', () {
        const data = {'name': 'John', 'email': 'john@test.com'};
        const event = DynamicFormSubmitEvent(data);
        expect(event.props, [data]);
      });

      test('data getter returns the correct map', () {
        const data = {'key': 'value'};
        const event = DynamicFormSubmitEvent(data);
        expect(event.data, data);
      });

      test('supports empty data map', () {
        const event1 = DynamicFormSubmitEvent({});
        const event2 = DynamicFormSubmitEvent({});
        expect(event1, equals(event2));
        expect(event1.data, isEmpty);
      });

      test('toString contains class name', () {
        const event = DynamicFormSubmitEvent({'name': 'John'});
        final str = event.toString();
        expect(str, contains('DynamicFormSubmitEvent'));
      });

      test('is a subclass of DynamicFormEvent', () {
        const event = DynamicFormSubmitEvent({'name': 'John'});
        expect(event, isA<DynamicFormEvent>());
      });
    });

    group('DynamicFormResetEvent', () {
      test('supports value equality', () {
        const event1 = DynamicFormResetEvent();
        const event2 = DynamicFormResetEvent();
        expect(event1, equals(event2));
      });

      test('props is empty list (inherits from base)', () {
        const event = DynamicFormResetEvent();
        expect(event.props, <Object?>[]);
      });

      test('toString contains class name', () {
        const event = DynamicFormResetEvent();
        expect(event.toString(), contains('DynamicFormResetEvent'));
      });

      test('is a subclass of DynamicFormEvent', () {
        const event = DynamicFormResetEvent();
        expect(event, isA<DynamicFormEvent>());
      });

      test('all instances are equal because there are no fields', () {
        const events = [DynamicFormResetEvent(), DynamicFormResetEvent(), DynamicFormResetEvent()];
        for (final e in events) {
          expect(e, equals(events.first));
        }
      });
    });

    group('cross-event equality', () {
      test('different event types are not equal', () {
        const load = DynamicFormLoadEvent('form_1');
        const submit = DynamicFormSubmitEvent({'form_1': true});
        const reset = DynamicFormResetEvent();
        const base = DynamicFormEvent();

        expect(load, isNot(equals(submit)));
        expect(load, isNot(equals(reset)));
        expect(submit, isNot(equals(reset)));
        expect(base, isNot(equals(load)));
      });
    });
  });

  group('DynamicFormBloc', () {
    test('initial state is DynamicFormState with initial status', () {
      final bloc = DynamicFormBloc();
      expect(bloc.state, const DynamicFormState());
      expect(bloc.state.status, DynamicFormStatus.initial);
      bloc.close();
    });

    group('DynamicFormLoadEvent', () {
      blocTest<DynamicFormBloc, DynamicFormState>(
        'emits [loading, loaded] when API returns valid form schema',
        setUp: () => stub.stubSuccess(data: _validFormSchemaJson),
        build: () => DynamicFormBloc(),
        act: (bloc) => bloc.add(const DynamicFormLoadEvent('test_form')),
        wait: const Duration(milliseconds: 300),
        expect: () => [
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loading),
          isA<DynamicFormState>()
              .having((s) => s.status, 'status', DynamicFormStatus.loaded)
              .having((s) => s.schema, 'schema', isNotNull)
              .having((s) => s.schema!.id, 'schema.id', 'test_form')
              .having((s) => s.schema!.title, 'schema.title', 'Test Form')
              .having((s) => s.schema!.fields, 'schema.fields', hasLength(3)),
        ],
      );

      blocTest<DynamicFormBloc, DynamicFormState>(
        'emits [loading, failure] when API returns connection error',
        setUp: () => stub.stubDioError(DioExceptionType.connectionError, message: 'Connection failed'),
        build: () => DynamicFormBloc(),
        act: (bloc) => bloc.add(const DynamicFormLoadEvent('test_form')),
        wait: const Duration(milliseconds: 300),
        expect: () => [
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loading),
          isA<DynamicFormState>()
              .having((s) => s.status, 'status', DynamicFormStatus.failure)
              .having((s) => s.error, 'error', isNotNull),
        ],
      );

      blocTest<DynamicFormBloc, DynamicFormState>(
        'emits [loading, failure] when API returns 404',
        setUp: () => stub.stubDioError(DioExceptionType.badResponse, statusCode: 404, data: 'Not found'),
        build: () => DynamicFormBloc(),
        act: (bloc) => bloc.add(const DynamicFormLoadEvent('unknown')),
        wait: const Duration(milliseconds: 300),
        expect: () => [
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loading),
          isA<DynamicFormState>()
              .having((s) => s.status, 'status', DynamicFormStatus.failure)
              .having((s) => s.error, 'error', isNotNull),
        ],
      );

      blocTest<DynamicFormBloc, DynamicFormState>(
        'emits [loading, failure] when API returns timeout',
        setUp: () => stub.stubDioError(DioExceptionType.connectionTimeout, message: 'Timeout'),
        build: () => DynamicFormBloc(),
        act: (bloc) => bloc.add(const DynamicFormLoadEvent('test_form')),
        wait: const Duration(milliseconds: 300),
        expect: () => [
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loading),
          isA<DynamicFormState>()
              .having((s) => s.status, 'status', DynamicFormStatus.failure)
              .having((s) => s.error, 'error', contains('Timeout')),
        ],
      );
    });

    group('DynamicFormSubmitEvent', () {
      blocTest<DynamicFormBloc, DynamicFormState>(
        'does nothing when schema is null',
        build: () => DynamicFormBloc(),
        act: (bloc) => bloc.add(const DynamicFormSubmitEvent({'name': 'John'})),
        expect: () => <DynamicFormState>[],
      );

      blocTest<DynamicFormBloc, DynamicFormState>(
        'emits [submitting, submitted] with "Form data logged" when no submitAction',
        setUp: () => stub.stubSuccess(data: _formSchemaNoAction),
        build: () => DynamicFormBloc(),
        act: (bloc) async {
          bloc.add(const DynamicFormLoadEvent('no_action_form'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          bloc.add(const DynamicFormSubmitEvent({'name': 'John'}));
        },
        wait: const Duration(milliseconds: 300),
        expect: () => [
          // Load events
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loading),
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loaded),
          // Submit events
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.submitting),
          isA<DynamicFormState>()
              .having((s) => s.status, 'status', DynamicFormStatus.submitted)
              .having((s) => s.submitResponse, 'submitResponse', 'Form data logged'),
        ],
      );

      blocTest<DynamicFormBloc, DynamicFormState>(
        'emits [submitting, submitted] with POST when submitAction method is POST',
        setUp: () => stub.stubSuccess(data: _validFormSchemaJson),
        build: () => DynamicFormBloc(),
        act: (bloc) async {
          bloc.add(const DynamicFormLoadEvent('test_form'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          // After loading, stub the submit response
          stub.stubSuccess(data: '{"id": "lead_1"}');
          bloc.add(const DynamicFormSubmitEvent({'name': 'John', 'email': 'john@test.com'}));
        },
        wait: const Duration(milliseconds: 300),
        expect: () => [
          // Load events
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loading),
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loaded),
          // Submit events
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.submitting),
          isA<DynamicFormState>()
              .having((s) => s.status, 'status', DynamicFormStatus.submitted)
              .having((s) => s.submitResponse, 'submitResponse', '{"id": "lead_1"}'),
        ],
      );

      blocTest<DynamicFormBloc, DynamicFormState>(
        'emits [submitting, submitted] with PUT when submitAction method is PUT',
        setUp: () => stub.stubSuccess(data: _formSchemaPutAction),
        build: () => DynamicFormBloc(),
        act: (bloc) async {
          bloc.add(const DynamicFormLoadEvent('put_form'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          stub.stubSuccess(data: '{"updated": true}');
          bloc.add(const DynamicFormSubmitEvent({'name': 'Jane'}));
        },
        wait: const Duration(milliseconds: 300),
        expect: () => [
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loading),
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loaded),
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.submitting),
          isA<DynamicFormState>()
              .having((s) => s.status, 'status', DynamicFormStatus.submitted)
              .having((s) => s.submitResponse, 'submitResponse', '{"updated": true}'),
        ],
      );

      blocTest<DynamicFormBloc, DynamicFormState>(
        'emits [submitting, failure] when submit API call fails',
        setUp: () => stub.stubSuccess(data: _validFormSchemaJson),
        build: () => DynamicFormBloc(),
        act: (bloc) async {
          bloc.add(const DynamicFormLoadEvent('test_form'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          stub.stubDioError(DioExceptionType.badResponse, statusCode: 500, data: 'Internal Server Error');
          bloc.add(const DynamicFormSubmitEvent({'name': 'John'}));
        },
        wait: const Duration(milliseconds: 300),
        expect: () => [
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loading),
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loaded),
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.submitting),
          isA<DynamicFormState>()
              .having((s) => s.status, 'status', DynamicFormStatus.failure)
              .having((s) => s.error, 'error', isNotNull),
        ],
      );
    });

    group('DynamicFormResetEvent', () {
      blocTest<DynamicFormBloc, DynamicFormState>(
        'emits initial state when reset is dispatched',
        setUp: () => stub.stubSuccess(data: _validFormSchemaJson),
        build: () => DynamicFormBloc(),
        act: (bloc) async {
          bloc.add(const DynamicFormLoadEvent('test_form'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          bloc.add(const DynamicFormResetEvent());
        },
        wait: const Duration(milliseconds: 300),
        expect: () => [
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loading),
          isA<DynamicFormState>().having((s) => s.status, 'status', DynamicFormStatus.loaded),
          isA<DynamicFormState>()
              .having((s) => s.status, 'status', DynamicFormStatus.initial)
              .having((s) => s.schema, 'schema', isNull)
              .having((s) => s.error, 'error', isNull)
              .having((s) => s.submitResponse, 'submitResponse', isNull),
        ],
      );

      blocTest<DynamicFormBloc, DynamicFormState>(
        'emits initial state when reset is dispatched from initial state',
        build: () => DynamicFormBloc(),
        act: (bloc) => bloc.add(const DynamicFormResetEvent()),
        expect: () => [const DynamicFormState()],
      );
    });
  });

  group('DynamicFormStatus', () {
    test('has all expected enum values', () {
      expect(
        DynamicFormStatus.values,
        containsAll([
          DynamicFormStatus.initial,
          DynamicFormStatus.loading,
          DynamicFormStatus.loaded,
          DynamicFormStatus.submitting,
          DynamicFormStatus.submitted,
          DynamicFormStatus.failure,
        ]),
      );
    });

    test('has exactly 6 values', () {
      expect(DynamicFormStatus.values, hasLength(6));
    });
  });
}
