import 'dart:convert';

import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';

class FormSchemaModel extends FormSchemaEntity {
  const FormSchemaModel({
    required super.id,
    required super.title,
    super.description,
    super.fields,
    super.submitAction,
    super.layout,
  });

  static FormSchemaModel fromJson(Map<String, dynamic> json) {
    final fieldsRaw = json['fields'] as List<dynamic>? ?? [];
    final fields = fieldsRaw.map((f) => _parseField(f as Map<String, dynamic>)).toList();

    final submitRaw = json['submitAction'] as Map<String, dynamic>?;
    final submitAction = submitRaw != null
        ? FormSubmitAction(method: submitRaw['method'] as String, endpoint: submitRaw['endpoint'] as String)
        : null;

    return FormSchemaModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fields: fields,
      submitAction: submitAction,
      layout: _parseLayout(json['layout'] as String?),
    );
  }

  static FormSchemaModel fromJsonString(String jsonString) {
    return fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  static FormFieldEntity _parseField(Map<String, dynamic> json) {
    return FormFieldEntity(
      type: _parseFieldType(json['type'] as String),
      key: json['key'] as String,
      label: json['label'] as String,
      hint: json['hint'] as String?,
      required: json['required'] == true,
      readOnly: json['readOnly'] == true,
      defaultValue: json['default'],
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      validators: (json['validators'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      maxLines: json['maxLines'] as int?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
    );
  }

  static FormFieldType _parseFieldType(String type) {
    return switch (type) {
      'text' => FormFieldType.text,
      'email' => FormFieldType.email,
      'password' => FormFieldType.password,
      'number' => FormFieldType.number,
      'phone' => FormFieldType.phone,
      'textarea' => FormFieldType.textarea,
      'dropdown' => FormFieldType.dropdown,
      'multi_select' || 'multiSelect' => FormFieldType.multiSelect,
      'date' => FormFieldType.date,
      'datetime' => FormFieldType.datetime,
      'toggle' => FormFieldType.toggle,
      'checkbox' => FormFieldType.checkbox,
      'radio' => FormFieldType.radio,
      'slider' => FormFieldType.slider,
      'section_header' || 'sectionHeader' => FormFieldType.sectionHeader,
      'divider' => FormFieldType.divider,
      _ => FormFieldType.text,
    };
  }

  static FormLayout _parseLayout(String? layout) {
    return switch (layout) {
      'singleColumn' || 'single_column' => FormLayout.singleColumn,
      'twoColumn' || 'two_column' => FormLayout.twoColumn,
      _ => FormLayout.responsive,
    };
  }
}
