import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../../generated/l10n.dart';
import '../../../../utils/app_constants.dart';
import '../../../common_blocs/authorities/authorities_bloc.dart';
import '../../../common_blocs/sales_people/sales_people_bloc.dart';

class CreateFormPhoneNumber extends StatelessWidget {
  const CreateFormPhoneNumber({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'phoneNumber',
      decoration: InputDecoration(
        labelText: S.of(context).phone_number,
      ),
      validator: FormBuilderValidators.compose(
        [
          FormBuilderValidators.required(
              errorText: S.of(context).required_phone_type),
          FormBuilderValidators.minLength(
              errorText: S.of(context).required_phone_type, 10),
          FormBuilderValidators.maxLength(
              errorText: S.of(context).required_phone_type, 10),
        ],
      ),
    );
  }
}
class CreateFormPhoneActive extends StatelessWidget {
  const CreateFormPhoneActive({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderSwitch(
      name: 'userCreateActive',
      title: Text(S.of(context).active),
      initialValue: true,
    );
  }
}

class CreateFormEmail extends StatelessWidget {
  const CreateFormEmail({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'email',
      decoration: InputDecoration(
        labelText: S.of(context).email,
      ),
      validator: FormBuilderValidators.compose(
        [
          FormBuilderValidators.required(
              errorText: S.of(context).email_required),
          FormBuilderValidators.email(
              errorText: S.of(context).email_pattern),
        ],
      ),
    );
  }
}

class CreateFormLastname extends StatelessWidget {
  const CreateFormLastname({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'lastName',
      decoration: InputDecoration(
        labelText: S.of(context).last_name,
      ),
      inputFormatters: [
        UpperCaseTextFormatter(),
      ],
      validator: FormBuilderValidators.compose(
        [
          FormBuilderValidators.required(
              errorText: S.of(context).lastname_required),
          FormBuilderValidators.minLength(
              errorText: S.of(context).lastname_min_length, 3),
          FormBuilderValidators.maxLength(
              errorText: S.of(context).lastname_max_length, 20),
        ],
      ),
    );
  }
}

class CreateFormFirstName extends StatelessWidget {
  const CreateFormFirstName({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'firstName',
      decoration: InputDecoration(
        labelText: S.of(context).first_name,
      ),
      inputFormatters: [
        UpperCaseTextFormatter(),
      ],
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(
            errorText: S.of(context).firstname_required),
        FormBuilderValidators.minLength(
            errorText: S.of(context).firstname_min_length, 3),
        FormBuilderValidators.maxLength(
            errorText: S.of(context).firstname_max_length, 20),
      ]),
    );
  }
}

class CreateFormLoginName extends StatelessWidget {
  const CreateFormLoginName({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'login',
      decoration: InputDecoration(
        labelText: S.of(context).login,
      ),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(
            errorText: S.of(context).username_required),
        FormBuilderValidators.minLength(
            errorText: S.of(context).username_min_length, 3),
        FormBuilderValidators.maxLength(
            errorText: S.of(context).username_max_length, 20),
        FormBuilderValidators.match("^[a-zA-Z0-9]+\$" as RegExp,
            errorText: S.of(context).username_regex_pattern),
      ]),
    );
  }
}

class CreateFormAuthorities extends StatelessWidget {
  final GlobalKey<FormBuilderState>? formKey;

  const CreateFormAuthorities({super.key, this.formKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthoritiesBloc, AuthoritiesState>(
      builder: (context, state) {
        if (state is AuthoritiesLoadSuccessState) {
          return FormBuilderDropdown(
            name: 'authorities',
            decoration: InputDecoration(
              hintText: S.of(context).authorities,
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText: S.of(context).authorities_required),
            ]),
            items: state.role
                .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    ))
                .toList(),
            initialValue: "",
            onChanged: (value) {
              if (value == "ROLE_MARKETING") {
                BlocProvider.of<SalesPersonBloc>(context)
                    .add(SalesPersonLoad());
              }
              if (value == "ROLE_ADMIN") {
                BlocProvider.of<SalesPersonBloc>(context)
                    .add(SalesPersonLoadDefault());
                formKey?.currentState!.fields['salesPersonCode']?.didChange("");
              }
            },
          );
        } else
          return Container();
      },
    );
  }
}

class CreateFormSalesPerson extends StatelessWidget {
  final GlobalKey<FormBuilderState>? formKey;
  const CreateFormSalesPerson({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesPersonBloc, SalesPersonState>(
      builder: (context, state) {
        if (state is SalesPersonLoadSuccessState) {
          return FormBuilderDropdown(
            name: 'salesPersonName',
            decoration: InputDecoration(
              labelText: S.of(context).plasiyer,
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText: S.of(context).required_salesPerson),
            ]),
            items: state.salesPerson
                .map((salesPerson) => DropdownMenuItem(
                      value: salesPerson,
                      child: Text(salesPerson.name?.toString() ?? ""),
                    ))
                .toList(),
            onChanged: (value) {
              log("value: $value");
              if (value != formKey?.currentState!.fields['salesPersonName']?.value)
              formKey?.currentState!.fields['salesPersonName']!.didChange(value);
            },
          );
        } else
          return Container();
      },
    );
  }
}
