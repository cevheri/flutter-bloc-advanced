import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_utils.dart';

/// Input-validation guard regressions. The guards short-circuit before
/// any network call so we don't need a stubbed Dio here — the no-call
/// path is exactly what's being asserted.
void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
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
}
