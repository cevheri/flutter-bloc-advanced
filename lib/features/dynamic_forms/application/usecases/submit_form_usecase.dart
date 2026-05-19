import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/repositories/dynamic_form_repository.dart';

class SubmitFormUseCase {
  const SubmitFormUseCase(this._repository);

  final IDynamicFormRepository _repository;

  Future<Result<String?>> call(FormSubmitAction action, Map<String, dynamic> data) {
    return _repository.submit(action, data);
  }
}
