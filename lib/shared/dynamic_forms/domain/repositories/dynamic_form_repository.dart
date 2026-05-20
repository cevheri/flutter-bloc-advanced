import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';

/// Domain port for dynamic-form persistence and dispatch.
///
/// Defined here (domain layer) so the application layer can depend on
/// an abstraction; the data layer provides the HTTP-backed impl.
abstract class IDynamicFormRepository {
  /// Fetch the schema describing the form fields, layout, and submit
  /// action for [formId].
  Future<Result<FormSchemaEntity>> fetchSchema(String formId);

  /// Fetch a schema bundled with prefilled values from [basePath], optionally
  /// appending [pathParams] as a trailing URL segment. Used by forms whose
  /// schema and values are served together (e.g. user extended-info). Passing
  /// path parameters via the named arg (instead of pre-composing them into
  /// [basePath]) keeps the mock-interceptor file name stable across instances,
  /// so a single fixture can serve every user/entity id.
  Future<Result<FormBundleEntity>> fetchBundle(String basePath, {String? pathParams});

  /// Dispatch the user-entered [data] to the submit endpoint described
  /// by [action]. If [pathParams] is provided, it is appended as a
  /// trailing URL segment (matching the per-instance routing used by
  /// [fetchBundle]). Returns the server response body as a string, or
  /// `null` if the response had no body.
  Future<Result<String?>> submit(FormSubmitAction action, Map<String, dynamic> data, {String? pathParams});
}
