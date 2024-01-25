import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../data/models/refinery.dart';
import '../../../../generated/l10n.dart';
import '../../../../utils/app_constants.dart';
import '../../../../utils/message.dart';
import '../bloc/refinery_bloc.dart';

class RefineryEditFormName extends StatelessWidget {
  final Refinery refinery;

  const RefineryEditFormName({super.key, required this.refinery});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'refineryEditFormName',
      decoration: InputDecoration(
        labelText: S.of(context).name,
      ),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).name_required),
      ]),
      initialValue: refinery.name,
    );
  }
}

class RefineryEditFormDescription extends StatelessWidget {
  final Refinery refinery;

  const RefineryEditFormDescription({super.key, required this.refinery});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'refineryEditFormDescription',
      decoration: InputDecoration(
        labelText: S.of(context).description,
      ),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).description_required),
      ]),
      initialValue: refinery.description,
    );
  }
}

class RefineryEditFormActive extends StatelessWidget {
  final Refinery refinery;

  const RefineryEditFormActive({super.key, required this.refinery});

  @override
  Widget build(BuildContext context) {
    return FormBuilderSwitch(
      name: 'refineryEditFormActive',
      title: Text(S.of(context).active),
      initialValue: refinery.active,
    );
  }
}

class RefineryEditFormPrice extends StatelessWidget {
  final Refinery refinery;
  final GlobalKey<FormBuilderState>? refineryEditFormKey;

  const RefineryEditFormPrice({super.key, required this.refinery, required this.refineryEditFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'refineryEditFormPrice',
      decoration: InputDecoration(
        labelText: S.of(context).price,
      ),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).price_required),
      ]),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,8}')),
        CommaFormatter(),
      ],
      onChanged: (value) {
        if (refineryEditFormKey!.currentState!.fields['refineryEditFormPrice']!.value != null) {
          refineryEditFormKey!.currentState!.fields['refineryEditFormPriceWithVat']!.didChange((double.parse(value!) * 1.2).toString());
        }
      },
      initialValue: refinery.price.toString(),
    );
  }
}

class RefineryEditFormPriceWithVat extends StatelessWidget {
  final Refinery refinery;
  final GlobalKey<FormBuilderState>? refineryEditFormKey;

  const RefineryEditFormPriceWithVat({super.key, required this.refinery, required this.refineryEditFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'refineryEditFormPriceWithVat',
      decoration: InputDecoration(
        labelText: S.of(context).price_with_vat,
      ),
      initialValue: refinery.priceWithVat.toString(),
      enabled: false,
    );
  }
}

class RefineryEditSubmitButton extends StatelessWidget {
  final Refinery refinery;
  final GlobalKey<FormBuilderState>? refineryEditFormKey;

  const RefineryEditSubmitButton(BuildContext context, {super.key, required this.refineryEditFormKey, required this.refinery});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RefineryBloc, RefineryState>(
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            child: Text(S.of(context).edit_refinery),
            onPressed: () {
              if (refineryEditFormKey!.currentState!.saveAndValidate()) {
                Refinery cachedRefinery = Refinery(
                  id: refinery.id,
                  name: refinery.name,
                  description: refinery.description,
                  active: refinery.active,
                  price: refinery.price,
                  priceWithVat: refinery.priceWithVat,
                );
                Refinery refineryEdit = Refinery(
                  id: refinery.id,
                  name: refineryEditFormKey!.currentState!.fields['refineryEditFormName']?.value ?? "",
                  description: refineryEditFormKey!.currentState!.fields['refineryEditFormDescription']?.value ?? "",
                  active: refineryEditFormKey!.currentState!.fields['refineryEditFormActive']?.value ?? "",
                  price: double.parse(refineryEditFormKey!.currentState!.fields['refineryEditFormPrice']?.value ?? ""),
                  priceWithVat: double.parse(refineryEditFormKey!.currentState!.fields['refineryEditFormPriceWithVat']?.value ?? ""),
                );
                if (cachedRefinery != refineryEdit) {
                  BlocProvider.of<RefineryBloc>(context).add(RefineryUpdate(refinery: refineryEdit));
                } else {
                  Message.getMessage(context: context, title: "Değişiklik Bulunamadı", content: "");
                }
              }
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is RefineryUpdateInitialState) {
          Message.getMessage(context: context, title: "Kayıt Güncelleniyor", content: "");
        }
        if (current is RefineryUpdateSuccessState) {
          Message.getMessage(context: context, title: "Kayıt Güncellendi", content: "");
          Navigator.pop(context);
        }
        if (current is RefineryUpdateFailureState) {
          Message.errorMessage(title: 'Kayıt Güncellenemedi.', context: context, content: "");
        }
        return true;
      },
    );
  }
}
