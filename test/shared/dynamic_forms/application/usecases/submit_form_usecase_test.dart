import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/usecases/submit_form_usecase.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements IDynamicFormRepository {
  Result<String?>? submitResult;
  FormSubmitAction? lastAction;
  Map<String, dynamic>? lastData;

  @override
  Future<Result<FormSchemaEntity>> fetchSchema(String formId) async => const Failure(UnknownError('not used'));

  @override
  Future<Result<FormBundleEntity>> fetchBundle(String basePath, {String? pathParams}) async =>
      const Failure(UnknownError('not used'));

  @override
  Future<Result<String?>> submit(FormSubmitAction action, Map<String, dynamic> data, {String? pathParams}) async {
    lastAction = action;
    lastData = data;
    return submitResult ?? const Failure(UnknownError('not configured'));
  }
}

void main() {
  test('forwards action + data to the repository on call', () async {
    final repo = _FakeRepo()..submitResult = const Success('{"ok":true}');
    final useCase = SubmitFormUseCase(repo);
    const action = FormSubmitAction(method: 'POST', endpoint: '/leads');

    final result = await useCase(action, const {'name': 'Alice'});

    expect(result, isA<Success<String?>>());
    expect(repo.lastAction, action);
    expect(repo.lastData, const {'name': 'Alice'});
  });

  test('propagates a repository Failure unchanged', () async {
    final repo = _FakeRepo()..submitResult = const Failure(ValidationError('bad endpoint'));
    final useCase = SubmitFormUseCase(repo);
    const action = FormSubmitAction(method: 'POST', endpoint: '/leads');

    final result = await useCase(action, const {});

    expect(result, isA<Failure<String?>>());
    expect((result as Failure).error, isA<ValidationError>());
  });
}
