import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';

enum DynamicFormStatus { initial, loading, loaded, submitting, submitted, failure }

class DynamicFormState extends Equatable {
  const DynamicFormState({this.status = DynamicFormStatus.initial, this.schema, this.submitResponse, this.error});

  final DynamicFormStatus status;
  final FormSchemaEntity? schema;
  final String? submitResponse;
  final String? error;

  DynamicFormState copyWith({
    DynamicFormStatus? status,
    FormSchemaEntity? schema,
    String? submitResponse,
    String? error,
  }) {
    return DynamicFormState(
      status: status ?? this.status,
      schema: schema ?? this.schema,
      submitResponse: submitResponse ?? this.submitResponse,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, schema, submitResponse, error];
}
