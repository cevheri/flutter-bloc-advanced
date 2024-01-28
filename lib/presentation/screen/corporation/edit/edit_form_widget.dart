import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../data/models/corporation.dart';
import '../../../../generated/l10n.dart';
import '../../../../utils/message.dart';
import '../bloc/corporation_bloc.dart';

class CorporationEditFormName extends StatelessWidget {
  final Corporation corporation;

  const CorporationEditFormName({super.key, required this.corporation});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'corporationEditFormName',
      decoration: InputDecoration(
        labelText: S.of(context).name,
      ),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).name_required),
      ]),
      initialValue: corporation.name,
    );
  }
}

class CorporationEditFormDescription extends StatelessWidget {
  final Corporation corporation;

  const CorporationEditFormDescription({super.key, required this.corporation});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'corporationEditFormDescription',
      decoration: InputDecoration(
        labelText: S.of(context).description,
      ),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).description_required),
      ]),
      initialValue: corporation.description,
    );
  }
}

class CorporationEditFormActive extends StatelessWidget {
  final Corporation corporation;

  const CorporationEditFormActive({super.key, required this.corporation});

  @override
  Widget build(BuildContext context) {
    return FormBuilderSwitch(
      name: 'corporationEditFormActive',
      title: Text(S.of(context).active),
      initialValue: corporation.active,
    );
  }
}

class CorporationEditSubmitButton extends StatelessWidget {
  final Corporation corporation;
  final GlobalKey<FormBuilderState>? corporationEditFormKey;

  const CorporationEditSubmitButton(BuildContext context, {super.key, required this.corporationEditFormKey, required this.corporation});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CorporationBloc, CorporationState>(
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            child: Text(S.of(context).edit_corporation),
            onPressed: () {
              if (corporationEditFormKey!.currentState!.saveAndValidate()) {
                Corporation cachedCorporation = Corporation(
                  id: corporation.id,
                  name: corporation.name,
                  description: corporation.description,
                  active: corporation.active,
                );
                Corporation corporationEdit = Corporation(
                  id: corporation.id,
                  name: corporationEditFormKey!.currentState!.fields['corporationEditFormName']?.value ?? "",
                  description: corporationEditFormKey!.currentState!.fields['corporationEditFormDescription']?.value ?? "",
                  active: corporationEditFormKey!.currentState!.fields['corporationEditFormActive']?.value ?? "",
                );

                if (cachedCorporation != corporationEdit) {
                  BlocProvider.of<CorporationBloc>(context).add(CorporationUpdate(corporation: corporationEdit));
                } else {
                  Message.getMessage(context: context, title: "Değişiklik Bulunamadı", content: "");
                }
              }
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is CorporationUpdateInitialState) {
          Message.getMessage(context: context, title: "Kayıt Güncelleniyor", content: "");
        }
        if (current is CorporationUpdateSuccessState) {
          Message.getMessage(context: context, title: "Kayıt Güncellendi", content: "");
          Navigator.pop(context);
        }
        if (current is CorporationUpdateFailureState) {
          Message.errorMessage(title: 'Kayıt Güncellenemedi.', context: context, content: "");
        }
        return true;
      },
    );
  }
}
