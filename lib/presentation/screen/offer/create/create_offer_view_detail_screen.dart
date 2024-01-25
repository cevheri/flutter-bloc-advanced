import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter_bloc_advance/data/models/customer.dart';
import 'package:flutter_bloc_advance/data/models/offer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../../../../data/http_utils.dart';
import '../../../../data/models/status_change.dart';
import '../../../../utils/OfferingStatusType.dart';
import '../bloc/offer/offer_bloc.dart';
import '../offer_screen_const.dart';
import '../offer_widget/offer_pdf_view_button_widget.dart';

class EditOfferScreen extends StatelessWidget {
  final List<Offer> offer;
  final Customer customer;
  final headerStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  EditOfferScreen({required this.offer, required this.customer}) : super(key: ApplicationKeys.editOfferScreen);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, offer),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).offer_form),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  _buildBody(BuildContext context, List<Offer> offer) {
    //offer.lenght
    List<Offer> offerSerializeList = [];
    for (var i = 0; i < offer.length; i++) {
      String offerEncode = "";
      offerEncode = HttpUtils.encodeUTF8(JsonMapper.serialize(offer[i]));
      Offer offerSerialize = Offer();
      offerSerialize = JsonMapper.deserialize<Offer>(offerEncode)!;
      offerSerializeList.add(offerSerialize);
    }

    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minWidth: 300, maxWidth: 700),
          padding: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Expanded(flex: 1, child: Container()),
                            Expanded(flex: 2, child: Text(S.of(context).offer_form, textAlign: TextAlign.center, style: headerStyle)),
                            Expanded(
                              flex: 1,
                              child: Text(
                                offerSerializeList[0].createdDate == null
                                    ? ""
                                    : offerSerializeList[0].createdDate.toString().substring(0, 10),
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        SizedBox(height: 10),
                        RowWidget(
                            title: S.of(context).company_name,
                            content: customer.name!.length > 40 ? '${customer.name!.substring(0, 40)}...' : customer.name!),
                        RowWidget(
                            title: S.of(context).refinery,
                            content: capitalize(offerSerializeList[0].refinery == null ? "" : offerSerializeList[0].refinery!.name!)),
                        RowWidget(
                            title: S.of(context).corporation,
                            content: capitalize(offerSerializeList[0].corporation == null ? "" : offerSerializeList[0].corporation!.name!)),
                        RowWidget(
                            title: S.of(context).station,
                            content: capitalize(offerSerializeList[0].station == null ? "" : offerSerializeList[0].station!.name!)),
                        RowWidget(
                            title: S.of(context).city,
                            content: capitalize(
                                offerSerializeList[0].destinationCity == null ? "" : offerSerializeList[0].destinationCity!.name!)),
                        RowWidget(
                            title: S.of(context).destination_district,
                            content: capitalize(
                                offerSerializeList[0].destinationDistrict == null ? "" : offerSerializeList[0].destinationDistrict!.name!)),
                        RowWidget(
                            title: S.of(context).transport_distance, content: "${offerSerializeList[0].transportDistance.toString()} Km"),
                        RowWidget(title: S.of(context).transport_cost, content: "${offerSerializeList[0].transportCost.toString()} ₺"),
                        RowWidget(title: S.of(context).birim, content: "${offerSerializeList[0].liter.toString()} Lt"),
                        offerSerializeList[0].description.toString() != "null"
                            ? RowWidget(title: S.of(context).description_offer, content: offerSerializeList[0].description.toString())
                            : Container(),
                        Divider(),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: ClampingScrollPhysics(),
                          itemCount: offer.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                RowWidget(
                                    title: S.of(context).maturity,
                                    content: offer[index].maturity.toString() == "-1"
                                        ? S.of(context).credit_card
                                        : "${offer[index].maturity} ${S.of(context).day}"),
                                RowWidget(
                                    title: S.of(context).price,
                                    content: offer[index].unitPrice != null
                                        ? "${offer[index].unitPrice!.toStringAsFixed(2).toString()} ₺"
                                        : "0.00 ₺"),
                                Column(
                                  children: [
                                    SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(S.of(context).increase, textAlign: TextAlign.left),
                                        ),
                                        SizedBox(width: 50),
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(offer[index].increase != null
                                                    ? "${offer[index].increase!.toStringAsFixed(2).toString()} ₺"
                                                    : "0.00 ₺"),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 100,
                                                      child: buildOfferApprovalInProgress(
                                                        context,
                                                        offerSerializeList[index],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(S.of(context).total_price, textAlign: TextAlign.left),
                                        ),
                                        SizedBox(width: 50),
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                    offer[index].totalPrice != null
                                                        ? "${offer[index].totalPrice!.toStringAsFixed(2).toString()} ₺"
                                                        : "0.00 ₺",
                                                    textAlign: TextAlign.left),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 100,
                                                      child: pdfOpenButton(customer, [offerSerializeList[index]], "PDF", context),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Divider(),
                              ],
                            );
                          },
                        ),
                        Column(
                          children: [
                            SizedBox(
                              width: 200,
                              child: pdfOpenButton(customer, offerSerializeList, "Bütün Fiyatlar (PDF)", context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BlocBuilder<OfferBloc, OfferState> buildOfferApprovalInProgress(BuildContext context, Offer offer) {
    return BlocBuilder<OfferBloc, OfferState>(
      builder: (context, state) {
        return TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Center(
            child: Text(
              S.of(context).send_offer,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          onPressed: () {
            BlocProvider.of<OfferBloc>(context).add(
              OfferStatusUpdate(
                statusChange: StatusChange(
                    offeringId: offer.id!,
                    statusId: OfferingStatusType.APPROVAL_IN_PROGRESS,
                    comment: OfferingStatusType.APPROVAL_IN_PROGRESS_DEFAULT_COMMENT),
              ),
            );
          },
        );
      },
    );
  }
}
