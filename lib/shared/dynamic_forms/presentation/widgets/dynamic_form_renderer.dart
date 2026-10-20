import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// Renders a [FormSchemaEntity] into a fully functional Flutter form.
///
/// Uses the project's design system components and `flutter_form_builder`
/// for validation. Each field type maps to a specific Flutter widget.
class DynamicFormRenderer extends StatelessWidget {
  const DynamicFormRenderer({
    super.key,
    required this.schema,
    required this.formKey,
    this.onSubmit,
    this.onChanged,
    this.readOnly = false,
    this.initialValues = const {},
  });

  final FormSchemaEntity schema;
  final GlobalKey<FormBuilderState> formKey;
  final ValueChanged<Map<String, dynamic>>? onSubmit;

  /// Called whenever a field of the form changes.
  final VoidCallback? onChanged;
  final bool readOnly;

  /// Prefilled values keyed by field key, taking precedence over each
  /// field's own [FormFieldEntity.defaultValue]. Lets callers hydrate the
  /// form from a server response without mutating the schema. Empty by
  /// default — existing schema-only callers behave exactly as before.
  final Map<String, dynamic> initialValues;

  dynamic _initialFor(FormFieldEntity field) =>
      initialValues.containsKey(field.key) ? initialValues[field.key] : field.defaultValue;

  /// Coerces a JSON-friendly date representation (ISO-8601 string or
  /// `DateTime`) into a `DateTime` for `FormBuilderDateTimePicker`. Returns
  /// null for missing or unparseable values rather than throwing, so a typo
  /// in a server response degrades gracefully to an empty picker.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      onChanged: onChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (schema.description != null) ...[
            Text(schema.description!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
          ],
          ...schema.fields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildField(context, field),
            ),
          ),
          if (onSubmit != null && !readOnly) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(label: S.of(context).submit, onPressed: _handleSubmit),
          ],
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      onSubmit?.call(formKey.currentState!.value);
    }
  }

  Widget _buildField(BuildContext context, FormFieldEntity field) {
    final l10n = S.of(context);
    return switch (field.type) {
      FormFieldType.text => _buildTextField(field, l10n),
      FormFieldType.email => _buildTextField(field, l10n, keyboardType: TextInputType.emailAddress),
      FormFieldType.password => _buildTextField(field, l10n, obscureText: true),
      FormFieldType.number => _buildTextField(field, l10n, keyboardType: TextInputType.number),
      FormFieldType.phone => _buildTextField(field, l10n, keyboardType: TextInputType.phone),
      FormFieldType.textarea => _buildTextField(field, l10n, maxLines: field.maxLines ?? 4),
      FormFieldType.dropdown => _buildDropdown(field, l10n),
      FormFieldType.multiSelect => _buildMultiSelect(field),
      FormFieldType.date => _buildDatePicker(field, l10n),
      FormFieldType.datetime => _buildDateTimePicker(field, l10n),
      FormFieldType.toggle => _buildToggle(field),
      FormFieldType.checkbox => _buildCheckbox(field),
      FormFieldType.radio => _buildRadioGroup(field),
      FormFieldType.slider => _buildSlider(field),
      FormFieldType.sectionHeader => _buildSectionHeader(context, field),
      FormFieldType.divider => const Divider(),
    };
  }

  Widget _buildTextField(
    FormFieldEntity field,
    S l10n, {
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return FormBuilderTextField(
      name: field.key,
      initialValue: _initialFor(field)?.toString(),
      decoration: InputDecoration(labelText: field.label, hintText: field.hint),
      readOnly: readOnly || field.readOnly,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: _buildValidators(field, l10n),
    );
  }

  Widget _buildDropdown(FormFieldEntity field, S l10n) {
    return FormBuilderDropdown<String>(
      name: field.key,
      initialValue: _initialFor(field)?.toString(),
      decoration: InputDecoration(labelText: field.label, hintText: field.hint),
      enabled: !readOnly && !field.readOnly,
      validator: _buildValidators(field, l10n),
      items: field.options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
    );
  }

  Widget _buildMultiSelect(FormFieldEntity field) {
    final initial = _initialFor(field);
    return FormBuilderCheckboxGroup<String>(
      name: field.key,
      initialValue: initial is List ? List<String>.from(initial.map((e) => e.toString())) : const [],
      decoration: InputDecoration(labelText: field.label),
      enabled: !readOnly && !field.readOnly,
      options: field.options.map((opt) => FormBuilderFieldOption(value: opt, child: Text(opt))).toList(),
    );
  }

  Widget _buildDatePicker(FormFieldEntity field, S l10n) {
    return FormBuilderDateTimePicker(
      name: field.key,
      inputType: InputType.date,
      initialValue: _parseDateTime(_initialFor(field)),
      decoration: InputDecoration(labelText: field.label, hintText: field.hint),
      enabled: !readOnly && !field.readOnly,
      validator: _buildValidators(field, l10n),
    );
  }

  Widget _buildDateTimePicker(FormFieldEntity field, S l10n) {
    return FormBuilderDateTimePicker(
      name: field.key,
      inputType: InputType.both,
      initialValue: _parseDateTime(_initialFor(field)),
      decoration: InputDecoration(labelText: field.label, hintText: field.hint),
      enabled: !readOnly && !field.readOnly,
      validator: _buildValidators(field, l10n),
    );
  }

  Widget _buildToggle(FormFieldEntity field) {
    return FormBuilderSwitch(
      name: field.key,
      initialValue: _initialFor(field) == true,
      title: Text(field.label),
      decoration: const InputDecoration(border: InputBorder.none),
      enabled: !readOnly && !field.readOnly,
    );
  }

  Widget _buildCheckbox(FormFieldEntity field) {
    return FormBuilderCheckbox(
      name: field.key,
      initialValue: _initialFor(field) == true,
      title: Text(field.label),
      decoration: const InputDecoration(border: InputBorder.none),
      enabled: !readOnly && !field.readOnly,
    );
  }

  Widget _buildRadioGroup(FormFieldEntity field) {
    return FormBuilderRadioGroup<String>(
      name: field.key,
      initialValue: _initialFor(field)?.toString(),
      decoration: InputDecoration(labelText: field.label),
      enabled: !readOnly && !field.readOnly,
      options: field.options.map((opt) => FormBuilderFieldOption(value: opt, child: Text(opt))).toList(),
    );
  }

  Widget _buildSlider(FormFieldEntity field) {
    return FormBuilderSlider(
      name: field.key,
      initialValue: (_initialFor(field) as num?)?.toDouble() ?? field.min ?? 0,
      min: field.min ?? 0,
      max: field.max ?? 100,
      decoration: InputDecoration(labelText: field.label),
      enabled: !readOnly && !field.readOnly,
    );
  }

  Widget _buildSectionHeader(BuildContext context, FormFieldEntity field) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(field.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  String? Function(dynamic)? _buildValidators(FormFieldEntity field, S l10n) {
    final validators = <String? Function(dynamic)>[];

    if (field.required) {
      validators.add((value) {
        if (value == null || (value is String && value.isEmpty)) return l10n.dynamic_form_field_required(field.label);
        return null;
      });
    }

    for (final v in field.validators) {
      if (v.startsWith('minLength:')) {
        final min = int.tryParse(v.split(':').last);
        if (min != null) {
          // An empty value is left to the required rule, so an optional field can be cleared again.
          validators.add((value) {
            if (value is String && value.isNotEmpty && value.length < min) {
              return l10n.dynamic_form_field_min_length(field.label, min);
            }
            return null;
          });
        }
      } else if (v.startsWith('maxLength:')) {
        final max = int.tryParse(v.split(':').last);
        if (max != null) {
          validators.add((value) {
            if (value is String && value.length > max) return l10n.dynamic_form_field_max_length(field.label, max);
            return null;
          });
        }
      } else if (v == 'email') {
        validators.add((value) {
          if (value is String && value.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return l10n.invalid_email;
          }
          return null;
        });
      } else if (v == 'numeric') {
        validators.add((value) {
          if (value is String && value.isNotEmpty && double.tryParse(value) == null) {
            return l10n.dynamic_form_field_numeric;
          }
          return null;
        });
      }
    }

    if (validators.isEmpty) return null;
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
