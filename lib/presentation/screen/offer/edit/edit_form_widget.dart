import 'package:flutter_bloc_advance/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/customer.dart';
import '../../../../data/models/offer.dart';
import '../../../../data/models/status.dart';
import '../../../../generated/l10n.dart';
import '../../../common_blocs/status/status_bloc.dart';
import '../list/list_widget.dart';
import '../offer_widget/offer_form_comment_widget.dart';
import '../offer_widget/offer_pdf_view_button_widget.dart';
import '../offer_screen_const.dart';

Future<dynamic> offerEditFormScreen(
  BuildContext context,
  Offer offer,
  Customer? customer,
  Status? status,
) async {
  final eoStatus = GlobalKey<FormBuilderState>();
  final eoPrice = GlobalKey<FormBuilderState>();
  final eoDescription = GlobalKey<FormBuilderState>();

  return showDialog(
    context: context,
    builder: (context) {
      BlocProvider.of<StatusBloc>(context).add(StatusListWithOffer(offerStatusId: offer.status!.id.toString()));
      double refinery = offer.refinery?.priceWithVat ?? 0;
      double rate = offer.selectedStationMaturityPrice?.rate ?? 0;
      double corporationRate = offer.selectedCorporationMaturityDate?.rate ?? 0;
      double quoteCost = refinery + ((refinery * rate) / 100);

      return AlertDialog(
        title: Text(S.of(context).offer_form, textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        contentPadding: EdgeInsets.fromLTRB(30, 30, 30, 30),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Divider(color: Colors.black, height: 0.2, thickness: 0.2),
              SizedBox(height: 10),
              RowWidget(title: S.of(context).name, content: customer!.name!),
              RowWidget(title: S.of(context).refinery, content: offer.refinery!.name!.capitalize()),
              RowWidget(title: S.of(context).corporation, content: offer.corporation!.name!.capitalize()),
              RowWidget(title: S.of(context).station, content: offer.station!.name!.capitalize()),
              RowWidget(title: S.of(context).city, content: offer.destinationCity!.name!.capitalize()),
              RowWidget(title: S.of(context).destination_district, content: offer.destinationDistrict!.name!.capitalize()),
              RowWidget(
                  title: S.of(context).transport_distance,
                  content:
                      "${NumberFormat.currency(locale: 'tr_TR', decimalDigits: 0, symbol: "").format(int.parse(offer.transportDistance.toString()))} Km"),
              RowWidget(
                  title: S.of(context).transport_cost,
                  content:
                      "${NumberFormat.currency(locale: 'tr_TR', decimalDigits: 0, symbol: "").format(int.parse(offer.transportCost.toString()))} ₺"),
              RowWidget(
                  title: S.of(context).litre,
                  content:
                      "${NumberFormat.currency(locale: 'tr_TR', decimalDigits: 0, symbol: "").format(int.parse(offer.liter.toString()))} Lt"),
              RowWidget(
                  title: S.of(context).maturity,
                  content: offer.maturity.toString() == "-1" ? S.of(context).credit_card : "${offer.maturity} ${S.of(context).day}"),
              SizedBox(height: 10),
              AppConstants.role == "ROLE_ADMIN"
                  ? Column(
                      children: [
                        Divider(color: Colors.red, height: 0.2, thickness: 0.2),
                        SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                "${S.of(context).refinery} KDV Dahil Fiyat",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            SizedBox(width: 50),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "$refinery ₺",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                S.of(context).station_rate,
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            SizedBox(width: 50),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "%  $rate",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                S.of(context).cost,
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            SizedBox(width: 50),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "$quoteCost ₺",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Dağıtım firması kâr oranı",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            SizedBox(width: 50),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "%  $corporationRate",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Divider(color: Colors.red, height: 0.2, thickness: 0.2),
                        SizedBox(height: 5),
                      ],
                    )
                  : Column(
                      children: const [
                        Divider(color: Colors.red, height: 0.2, thickness: 0.2),
                        SizedBox(height: 5),
                      ],
                    ),
              OfferCommentWidget(offer: offer, formKey: eoDescription),
              SizedBox(height: 5),
              Divider(color: Colors.red, height: 0.2, thickness: 0.2),
              SizedBox(height: 5),
              RowWidget(title: S.of(context).price, content: "${offer.unitPrice?.toStringAsFixed(2).toString().replaceAll(".", ",")} ₺"),
              RowWidget(
                  title: S.of(context).increase,
                  content: offer.increase == null ? " - " : "${offer.increase?.toStringAsFixed(2).toString().replaceAll(".", ",")} ₺"),
              OfferChangeStatusFormDropDownWidget(
                customer: customer,
                eoPrice: eoPrice,
                increase: offer.increase ?? 0,
                oldStatus: offer.status,
                eoStatus: eoStatus,
                offer: offer,
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(
    () {
      BlocProvider.of<StatusBloc>(context).add(StatusLoadList());
    },
  );
}
