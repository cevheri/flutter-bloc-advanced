import 'dart:convert';

import 'package:flutter_bloc_advance/features/dynamic_forms/data/models/form_schema_model.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_bundle_entity.dart';

/// Parses a `{ "schema": {...}, "values": {...} }` response body into a
/// [FormBundleEntity]. The schema is delegated to [FormSchemaModel.fromJson]
/// so that all field-type and layout parsing stays in one place.
class FormBundleModel {
  const FormBundleModel._();

  static FormBundleEntity fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final schemaJson = json['schema'] as Map<String, dynamic>;
    final valuesJson = json['values'] as Map<String, dynamic>? ?? const {};
    return FormBundleEntity(
      schema: FormSchemaModel.fromJson(schemaJson),
      values: Map<String, dynamic>.unmodifiable(valuesJson),
    );
  }
}
