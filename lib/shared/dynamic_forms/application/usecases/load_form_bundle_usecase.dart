import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';

class LoadFormBundleUseCase {
  const LoadFormBundleUseCase(this._repository);

  final IDynamicFormRepository _repository;

  Future<Result<FormBundleEntity>> call(String endpoint) => _repository.fetchBundle(endpoint);
}
