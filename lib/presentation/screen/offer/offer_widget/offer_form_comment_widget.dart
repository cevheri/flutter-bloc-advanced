import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/utils/message.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../data/models/offer.dart';
import '../../../../generated/l10n.dart';
import '../../../common_blocs/status/status_bloc.dart';
import '../bloc/offer/offer_bloc.dart';
import '../offer_screen_const.dart';

class OfferCommentWidget extends StatelessWidget {
  final Offer offer;
  final GlobalKey<FormBuilderState> formKey;

  const OfferCommentWidget({
    super.key,
    required this.offer,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatusBloc, StatusState>(
      builder: (context, state) {
        return FormBuilder(
          key: formKey,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text(S.of(context).update_description, style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              if (formKey.currentState != null) {
                                if (formKey.currentState!.saveAndValidate()) {
                                  if (formKey.currentState!.value['description']
                                          .substring(0, formKey.currentState!.value['description'].length - 1) ==
                                      offer.description.toString()) {
                                    Message.errorMessage(
                                        context: context, title: "Uyarı", content: "Açıklama alanında değişiklik bulunamadı.");
                                  } else {
                                    BlocProvider.of<OfferBloc>(context).add(
                                      OfferUpdateDescription(
                                        offer: Offer(
                                          id: offer.id,
                                          offeringType: offer.offeringType,
                                          description: formKey.currentState!.value['description'],
                                          rate: offer.rate,
                                          active: offer.active,
                                          completed: offer.completed,
                                          maturity: offer.maturity,
                                          liter: offer.liter,
                                          unitPrice: offer.unitPrice,
                                          totalPrice: offer.totalPrice,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 50),
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: backColor(context),
                      child: FormBuilderTextField(
                        name: 'description',
                        maxLines: 5,
                        style: TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(10),
                          border: InputBorder.none,
                        ),
                        initialValue: offer.description.toString() == "null" ? "" : "${offer.description.toString()}\n",
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
