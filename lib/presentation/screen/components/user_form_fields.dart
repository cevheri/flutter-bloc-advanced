import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// User form fields - shared across user editor, account, and register screens.
/// All fields inherit InputDecoration from the theme (no per-field border overrides).
class UserFormFields {
  static FormFieldValidator<dynamic> _requiredValidator(BuildContext context) {
    return FormBuilderValidators.required(errorText: S.of(context).required_field);
  }

  static List<dynamic> _txtValidator(BuildContext context) {
    return [
      _requiredValidator(context),
      FormBuilderValidators.minLength(2, errorText: S.of(context).min_length_2),
      FormBuilderValidators.maxLength(100, errorText: S.of(context).max_length_100),
    ];
  }

  static Widget usernameField(BuildContext context, String? initialValue, {bool enabled = true}) =>
      FormBuilderTextField(
        key: const Key('userEditorLoginFieldKey'),
        name: 'login',
        enabled: enabled,
        initialValue: initialValue,
        decoration: InputDecoration(hintText: S.of(context).login),
        validator: FormBuilderValidators.compose([..._txtValidator(context)]),
      );

  static Widget firstNameField(BuildContext context, String? initialValue, {bool enabled = true}) =>
      FormBuilderTextField(
        key: const Key('userEditorFirstNameFieldKey'),
        enabled: enabled,
        initialValue: initialValue,
        name: 'firstName',
        decoration: InputDecoration(hintText: S.of(context).first_name),
        validator: FormBuilderValidators.compose([..._txtValidator(context)]),
      );

  static Widget lastNameField(BuildContext context, String? initialValue, {bool enabled = true}) =>
      FormBuilderTextField(
        key: const Key('userEditorLastNameFieldKey'),
        enabled: enabled,
        initialValue: initialValue,
        name: 'lastName',
        decoration: InputDecoration(hintText: S.of(context).last_name),
        validator: FormBuilderValidators.compose([..._txtValidator(context)]),
      );

  static Widget emailField(BuildContext context, String? initialValue, {bool enabled = true}) => FormBuilderTextField(
    key: const Key('userEditorEmailFieldKey'),
    enabled: enabled,
    initialValue: initialValue,
    name: 'email',
    decoration: InputDecoration(hintText: S.of(context).email),
    validator: FormBuilderValidators.compose([
      ..._txtValidator(context),
      FormBuilderValidators.email(errorText: S.of(context).email_pattern),
    ]),
  );

  static Widget activatedField(
    BuildContext context,
    bool? initialValue, {
    bool enabled = true,
    bool showTitle = true,
  }) => FormBuilderSwitch(
    key: const Key('userEditorActivatedFieldKey'),
    enabled: enabled,
    initialValue: initialValue,
    name: 'activated',
    title: showTitle ? Text(S.of(context).active) : const SizedBox.shrink(),
  );

  static Widget authoritiesField(BuildContext context, List<String?>? initialValue, {bool enabled = true}) =>
      FormBuilderDropdown<String>(
        key: const Key('userEditorAuthoritiesFieldKey'),
        name: 'authorities',
        enabled: enabled,
        decoration: InputDecoration(labelText: S.of(context).authorities),
        items: initialValue?.map((e) => DropdownMenuItem(value: e, child: Text(e ?? ''))).toList() ?? [],
        validator: FormBuilderValidators.compose([_requiredValidator(context)]),
      );
}
