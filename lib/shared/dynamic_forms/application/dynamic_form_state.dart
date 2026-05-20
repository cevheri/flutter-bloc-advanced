import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';

/// Sealed state for the dynamic-form flow.
///
/// Variants enforce at compile time which fields are available where:
/// - schema is required from [DynamicFormLoaded] onward (the bloc cannot
///   submit before a schema is loaded);
/// - submitResponse only exists once a submit has completed;
/// - error is only carried on failure variants.
sealed class DynamicFormState extends Equatable {
  const DynamicFormState();
}

final class DynamicFormInitial extends DynamicFormState {
  const DynamicFormInitial();

  @override
  List<Object?> get props => const [];
}

final class DynamicFormLoading extends DynamicFormState {
  const DynamicFormLoading();

  @override
  List<Object?> get props => const [];
}

final class DynamicFormLoaded extends DynamicFormState {
  const DynamicFormLoaded({required this.schema, this.initialValues = const {}, this.submitPathParams});

  final FormSchemaEntity schema;
  final Map<String, dynamic> initialValues;

  /// Path parameter to append to the submit URL (e.g. the user id loaded
  /// from `DynamicFormLoadBundleEvent.pathParams`). Null when the schema's
  /// `submitAction.endpoint` is a complete URL on its own.
  final String? submitPathParams;

  @override
  List<Object?> get props => [schema, initialValues, submitPathParams];
}

final class DynamicFormSubmitting extends DynamicFormState {
  const DynamicFormSubmitting({required this.schema, this.submitPathParams});

  final FormSchemaEntity schema;
  final String? submitPathParams;

  @override
  List<Object?> get props => [schema, submitPathParams];
}

final class DynamicFormSubmitted extends DynamicFormState {
  const DynamicFormSubmitted({required this.schema, this.submitResponse, this.submitPathParams});

  final FormSchemaEntity schema;
  final String? submitResponse;
  final String? submitPathParams;

  @override
  List<Object?> get props => [schema, submitResponse, submitPathParams];
}

/// Failure can happen either at load time (no schema) or at submit time
/// (schema present from the prior [DynamicFormLoaded] state). Carries the
/// per-instance [submitPathParams] when present so a retry submit reuses
/// the same URL.
final class DynamicFormFailure extends DynamicFormState {
  const DynamicFormFailure({required this.error, this.schema, this.submitPathParams});

  final String error;
  final FormSchemaEntity? schema;
  final String? submitPathParams;

  @override
  List<Object?> get props => [error, schema, submitPathParams];
}
