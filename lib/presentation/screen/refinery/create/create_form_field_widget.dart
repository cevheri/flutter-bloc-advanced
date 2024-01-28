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

class RefineryCreateFormName extends StatelessWidget {
  final GlobalKey<FormBuilderState>? refineryFormKey;

  const RefineryCreateFormName({super.key, required this.refineryFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'createFormRefineryName',
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

class RefineryCreateFormDescription extends StatelessWidget {
  final GlobalKey<FormBuilderState>? refineryFormKey;

  const RefineryCreateFormDescription({super.key, required this.refineryFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'createFormRefineryDescription',
      decoration: InputDecoration(
        labelText: S.of(context).refineries_description,
      ),
    );
  }
}

class RefineryCreateFormPrice extends StatelessWidget {
  final GlobalKey<FormBuilderState>? refineryFormKey;

  const RefineryCreateFormPrice({super.key, required this.refineryFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
        name: 'createFormRefineryPrice',
        decoration: InputDecoration(
          labelText: S.of(context).price,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,8}')),
          CommaFormatter(),
        ],
        validator: FormBuilderValidators.compose(
          [
            FormBuilderValidators.required(errorText: S.of(context).price_empty),
            FormBuilderValidators.minLength(errorText: S.of(context).price_min_length, 1),
            FormBuilderValidators.maxLength(errorText: S.of(context).price_max_length, 10),
            FormBuilderValidators.match("^[0-9]+\$", errorText: S.of(context).price_regex_pattern),
          ],
        ),
        onChanged: (value) {
          if (refineryFormKey!.currentState!.fields['createFormRefineryPrice']!.value != null) {
            refineryFormKey!.currentState!.fields['createFormRefineryPriceWithVat']!.didChange((double.parse(value!) * 1.2).toString());
          }
        });
  }
}

class RefineryCreateFormPriceWithWat extends StatelessWidget {
  final GlobalKey<FormBuilderState>? refineryFormKey;

  const RefineryCreateFormPriceWithWat({super.key, required this.refineryFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'createFormRefineryPriceWithVat',
      decoration: InputDecoration(
        labelText: S.of(context).price_with_vat,
      ),
      enabled: false,
    );
  }
}

class RefineryCreateFormActive extends StatelessWidget {
  final GlobalKey<FormBuilderState>? refineryFormKey;

  const RefineryCreateFormActive({super.key, required this.refineryFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderSwitch(
      name: 'createFormRefineryActive',
      initialValue: true,
      title: Text(S.of(context).active),
    );
  }
}

class RefineryCreateFormSubmitButton extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createRefineryFormKey;

  const RefineryCreateFormSubmitButton(BuildContext context, {super.key, required this.createRefineryFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RefineryBloc, RefineryState>(
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            child: Text(S.of(context).create_refinery),
            onPressed: () {
              if (createRefineryFormKey!.currentState!.saveAndValidate()) {
                Refinery refinery = Refinery(
                  name: createRefineryFormKey!.currentState!.fields['createFormRefineryName']!.value,
                  description: createRefineryFormKey!.currentState!.fields['createFormRefineryDescription']!.value,
                  active: createRefineryFormKey!.currentState!.fields['createFormRefineryActive']!.value,
                  price: double.parse(createRefineryFormKey!.currentState!.fields['createFormRefineryPrice']!.value),
                  priceWithVat: double.parse(createRefineryFormKey!.currentState!.fields['createFormRefineryPriceWithVat']!.value),
                );

                BlocProvider.of<RefineryBloc>(context).add(RefineryCreate(refinery: refinery));
              }
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is RefineryInitialState) {
          Message.getMessage(context: context, title: "Kayıt Oluşturuluyor", content: "");
        }
        if (current is RefineryCreateSuccessState) {
          Message.getMessage(context: context, title: "Kayıt Oluşturuldu", content: "");
          Navigator.pop(context);
        }
        if (current is RefineryCreateFailureState) {
          Message.errorMessage(title: 'Kayıt Oluşturulamadı.', context: context, content: "");
        }

        return true;
      },
    );
  }
}
