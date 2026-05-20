import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/usecases/load_form_bundle_usecase.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements IDynamicFormRepository {
  Result<FormBundleEntity>? bundleResult;
  String? lastBasePath;
  String? lastPathParams;

  @override
  Future<Result<FormSchemaEntity>> fetchSchema(String formId) async => const Failure(UnknownError('not used'));

  @override
  Future<Result<FormBundleEntity>> fetchBundle(String basePath, {String? pathParams}) async {
    lastBasePath = basePath;
    lastPathParams = pathParams;
    return bundleResult ?? const Failure(UnknownError('not configured'));
  }

  @override
  Future<Result<String?>> submit(FormSubmitAction action, Map<String, dynamic> data, {String? pathParams}) async =>
      const Failure(UnknownError('not used'));
}

void main() {
  group('LoadFormBundleUseCase', () {
    test('forwards basePath and pathParams to the repository and returns its Result', () async {
      final bundle = const FormBundleEntity(
        schema: FormSchemaEntity(id: 'extended', title: 'Extended Info'),
        values: {'name': 'Alice', 'email': 'alice@example.com'},
      );
      final repo = _FakeRepo()..bundleResult = Success(bundle);
      final useCase = LoadFormBundleUseCase(repo);

      final result = await useCase('/admin/users/extended', pathParams: 'user-1');

      expect(result, isA<Success<FormBundleEntity>>());
      expect(repo.lastBasePath, '/admin/users/extended');
      expect(repo.lastPathParams, 'user-1');
    });

    test('propagates a repository Failure unchanged', () async {
      final repo = _FakeRepo()..bundleResult = const Failure(NetworkError('offline'));
      final useCase = LoadFormBundleUseCase(repo);

      final result = await useCase('/x');

      expect(result, isA<Failure<FormBundleEntity>>());
      expect((result as Failure).error, isA<NetworkError>());
    });
  });
}
