import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../data/models/corporation.dart';
import '../../../../generated/l10n.dart';
import '../../../../utils/message.dart';
import '../bloc/corporation_bloc.dart';

class CorporationCreateFormName extends StatelessWidget {
  final GlobalKey<FormBuilderState>? corporationFormKey;

  const CorporationCreateFormName({super.key, required this.corporationFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'createFormCorporationName',
      decoration: InputDecoration(
        labelText: S.of(context).name,
      ),
      validator: FormBuilderValidators.compose(
        [
          FormBuilderValidators.minLength(errorText: S.of(context).name_min_length, 1),
          FormBuilderValidators.maxLength(errorText: S.of(context).name_max_length, 50),
          FormBuilderValidators.match("^[a-zA-Z0-9]+\$", errorText: S.of(context).name_regex_pattern),
        ],
      ),
    );
  }
}

class CorporationCreateFormDescription extends StatelessWidget {
  final GlobalKey<FormBuilderState>? corporationFormKey;

  const CorporationCreateFormDescription({super.key, required this.corporationFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'createFormCorporationDescription',
      decoration: InputDecoration(
        labelText: S.of(context).refineries_description,
      ),
    );
  }
}

class CorporationCreateFormActive extends StatelessWidget {
  final GlobalKey<FormBuilderState>? corporationFormKey;

  const CorporationCreateFormActive({super.key, required this.corporationFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderSwitch(
      name: 'createFormCorporationActive',
      initialValue: true,
      title: Text(S.of(context).active),
    );
  }
}

class CorporationCreateFormSubmitButton extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createCorporationFormKey;

  const CorporationCreateFormSubmitButton(BuildContext context, {super.key, required this.createCorporationFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CorporationBloc, CorporationState>(
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            child: Text(S.of(context).create_corporation),
            onPressed: () {
              if (createCorporationFormKey!.currentState!.saveAndValidate()) {
                Corporation corporation = Corporation(
                  name: createCorporationFormKey!.currentState!.fields['createFormCorporationName']!.value,
                  description: createCorporationFormKey!.currentState!.fields['createFormCorporationDescription']!.value,
                  active: createCorporationFormKey!.currentState!.fields['createFormCorporationActive']!.value,
                );

                BlocProvider.of<CorporationBloc>(context).add(CorporationCreate(corporation: corporation));
              }
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is CorporationCreateInitialState) {
          Message.getMessage(context: context, title: "Kayıt Oluşturuluyor", content: "");
        }
        if (current is CorporationCreateSuccessState) {
          Message.getMessage(context: context, title: "Kayıt Oluşturuldu", content: "");
          Navigator.pop(context);
        }
        if (current is CorporationCreateFailureState) {
          Message.errorMessage(title: 'Kayıt Oluşturulamadı.', context: context, content: "");
        }

        return true;
      },
    );
  }
}
