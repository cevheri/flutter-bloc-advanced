import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';

/// Domain port for dynamic-form persistence and dispatch.
///
/// Defined here (domain layer) so the application layer can depend on
/// an abstraction; the data layer provides the HTTP-backed impl.
abstract class IDynamicFormRepository {
  /// Fetch the schema describing the form fields, layout, and submit
  /// action for [formId].
  Future<Result<FormSchemaEntity>> fetchSchema(String formId);

  /// Dispatch the user-entered [data] to the submit endpoint described
  /// by [action]. Returns the server response body as a string, or
  /// `null` if the response had no body.
  Future<Result<String?>> submit(FormSubmitAction action, Map<String, dynamic> data);
}
