import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// User form fields
/// This class contains the user form fields that are used in the user form.
/// The user form fields are used to display the user form fields in the user form.
class UserFormFields {
  static _requiredValidator(BuildContext context) {
    return FormBuilderValidators.required(errorText: S.of(context).required_field);
  }

  static _txtValidator(BuildContext context) {
    return [
      _requiredValidator(context),
      FormBuilderValidators.minLength(2, errorText: S.of(context).min_length_2),
      FormBuilderValidators.maxLength(100, errorText: S.of(context).max_length_100),
    ];
  }

  /// Username field
  /// This field is a text field that is used to display the username.
  ///
  /// [context] BuildContext current context
  /// [initialValue] String? initial value of the field
  /// [enabled] bool enable the field default is true
  /// return TextField
  static Widget usernameField(BuildContext context, String? initialValue, {bool enabled = true}) =>
      FormBuilderTextField(
        key: const Key('userEditorLoginFieldKey'),
        name: 'login',
        enabled: enabled,
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: S.of(context).login,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5), width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        validator: FormBuilderValidators.compose([..._txtValidator(context)]),
      );

  /// First name field
  /// This field is a text field that is used to display the first name.
  ///
  /// [context] BuildContext current context
  /// [initialValue] String? initial value of the field
  /// [enabled] bool enable the field default is true
  /// return TextField
  static Widget firstNameField(BuildContext context, String? initialValue, {bool enabled = true}) =>
      FormBuilderTextField(
        // Keep backward compatible key expected by tests
        key: const Key('userEditorFirstNameFieldKey'),
        enabled: enabled,
        initialValue: initialValue,
        name: 'firstName',
        decoration: InputDecoration(
          labelText: S.of(context).first_name,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        validator: FormBuilderValidators.compose([..._txtValidator(context)]),
      );

  /// Last name field
  /// This field is a text field that is used to display the last name.
  ///
  /// [context] BuildContext current context
  /// [initialValue] String? initial value of the field
  /// [enabled] bool enable the field default is true
  /// return TextField
  static Widget lastNameField(BuildContext context, String? initialValue, {bool enabled = true}) =>
      FormBuilderTextField(
        // Keep backward compatible key expected by tests
        key: const Key('userEditorLastNameFieldKey'),
        enabled: enabled,
        initialValue: initialValue,
        name: 'lastName',
        decoration: InputDecoration(
          labelText: S.of(context).last_name,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        validator: FormBuilderValidators.compose([..._txtValidator(context)]),
      );

  /// Email field
  /// This field is a text field that is used to display the email.
  ///
  /// [context] BuildContext current context
  /// [initialValue] String? initial value of the field
  /// [enabled] bool enable the field default is true
  /// return TextField
  static Widget emailField(BuildContext context, String? initialValue, {bool enabled = true}) => FormBuilderTextField(
    // Keep backward compatible key expected by tests
    key: const Key('userEditorEmailFieldKey'),
    enabled: enabled,
    initialValue: initialValue,
    name: 'email',
    decoration: InputDecoration(
      labelText: S.of(context).email,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
    ),
    validator: FormBuilderValidators.compose([
      ..._txtValidator(context),
      FormBuilderValidators.email(errorText: S.of(context).email_pattern),
    ]),
  );

  /// Activated field
  /// This field is a switch that is used to display the activated.
  ///
  /// [context] BuildContext current context
  /// [initialValue] bool? initial value of the field
  /// [enabled] bool enable the field default is true
  /// return Switch
  static Widget activatedField(BuildContext context, bool? initialValue, {bool enabled = true}) => FormBuilderSwitch(
    key: const Key('userEditorActivatedFieldKey'),
    enabled: enabled,
    initialValue: initialValue,
    name: 'activated',
    title: Text(S.of(context).active),
  );

  /// Authorities dropDown field
  /// This field is a dropDown field that is used to display the authorities.
  ///
  /// [context] BuildContext current context
  /// [initialValue] List<String>? initial value of the field
  /// [enabled] bool enable the field default is true
  static Widget authoritiesField(BuildContext context, List<String?>? initialValue, {bool enabled = true}) =>
      FormBuilderDropdown<String>(
        key: const Key('userEditorAuthoritiesFieldKey'),
        name: 'authorities',
        enabled: enabled,
        decoration: InputDecoration(
          labelText: S.of(context).authorities,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        items: initialValue?.map((e) => DropdownMenuItem(value: e, child: Text(e ?? ''))).toList() ?? [],
        validator: FormBuilderValidators.compose([_requiredValidator(context)]),
      );
}
