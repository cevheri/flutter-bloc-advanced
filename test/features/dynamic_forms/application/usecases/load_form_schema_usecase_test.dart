import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/usecases/load_form_schema_usecase.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements IDynamicFormRepository {
  Result<FormSchemaEntity>? schemaResult;
  String? lastFormId;

  @override
  Future<Result<FormSchemaEntity>> fetchSchema(String formId) async {
    lastFormId = formId;
    return schemaResult ?? const Failure(UnknownError('not configured'));
  }

  @override
  Future<Result<String?>> submit(FormSubmitAction action, Map<String, dynamic> data) async => const Success(null);
}

void main() {
  test('forwards the formId to the repository and returns its Result', () async {
    final repo = _FakeRepo()..schemaResult = const Success(FormSchemaEntity(id: 'leads', title: 'Leads'));
    final useCase = LoadFormSchemaUseCase(repo);

    final result = await useCase('leads');

    expect(result, isA<Success<FormSchemaEntity>>());
    expect(repo.lastFormId, 'leads');
  });

  test('propagates a repository Failure unchanged', () async {
    final repo = _FakeRepo()..schemaResult = const Failure(NetworkError('offline'));
    final useCase = LoadFormSchemaUseCase(repo);

    final result = await useCase('leads');

    expect(result, isA<Failure<FormSchemaEntity>>());
    expect((result as Failure).error.message, 'offline');
  });
}
