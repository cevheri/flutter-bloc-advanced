import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';

/// A schema bundled with its prefilled values, returned by endpoints that
/// serve server-driven forms whose values live next to their schema
/// (e.g. the user extended-info form).
class FormBundleEntity extends Equatable {
  const FormBundleEntity({required this.schema, this.values = const {}});

  final FormSchemaEntity schema;
  final Map<String, dynamic> values;

  @override
  List<Object?> get props => [schema, values];
}
