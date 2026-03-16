import 'package:equatable/equatable.dart';

/// A dynamic form definition loaded from a remote JSON schema.
class FormSchemaEntity extends Equatable {
  const FormSchemaEntity({
    required this.id,
    required this.title,
    this.description,
    this.fields = const [],
    this.submitAction,
    this.layout = FormLayout.responsive,
  });

  final String id;
  final String title;
  final String? description;
  final List<FormFieldEntity> fields;
  final FormSubmitAction? submitAction;
  final FormLayout layout;

  @override
  List<Object?> get props => [id, title, description, fields, submitAction, layout];
}

/// A single form field definition.
class FormFieldEntity extends Equatable {
  const FormFieldEntity({
    required this.type,
    required this.key,
    required this.label,
    this.hint,
    this.required = false,
    this.readOnly = false,
    this.defaultValue,
    this.options = const [],
    this.validators = const [],
    this.maxLines,
    this.min,
    this.max,
  });

  final FormFieldType type;
  final String key;
  final String label;
  final String? hint;
  final bool required;
  final bool readOnly;
  final dynamic defaultValue;
  final List<String> options;
  final List<String> validators;
  final int? maxLines;
  final double? min;
  final double? max;

  @override
  List<Object?> get props => [type, key, label, hint, required, readOnly, defaultValue, options, validators];
}

/// Submit action configuration.
class FormSubmitAction extends Equatable {
  const FormSubmitAction({required this.method, required this.endpoint});

  final String method;
  final String endpoint;

  @override
  List<Object?> get props => [method, endpoint];
}

/// Supported field types.
enum FormFieldType {
  text,
  email,
  password,
  number,
  phone,
  textarea,
  dropdown,
  multiSelect,
  date,
  datetime,
  toggle,
  checkbox,
  radio,
  slider,
  sectionHeader,
  divider,
}

/// Layout modes.
enum FormLayout { responsive, singleColumn, twoColumn }
