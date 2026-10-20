import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// The fewest characters a password field accepts.
const int passwordMinLength = 4;

/// The most characters a password field accepts.
const int passwordMaxLength = 20;

/// Validates a password that a user signs in with or sets: it is required and has between [passwordMinLength] and
/// [passwordMaxLength] characters, and the messages state those numbers.
FormFieldValidator<String> passwordValidator(BuildContext context) {
  return FormBuilderValidators.compose([
    FormBuilderValidators.required(errorText: S.of(context).required_field),
    FormBuilderValidators.minLength(passwordMinLength, errorText: S.of(context).password_min_length(passwordMinLength)),
    FormBuilderValidators.maxLength(passwordMaxLength, errorText: S.of(context).password_max_length(passwordMaxLength)),
  ]);
}
