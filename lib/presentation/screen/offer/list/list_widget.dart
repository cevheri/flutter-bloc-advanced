import 'package:flutter_bloc_advance/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/customer.dart';
import '../../../../data/models/offer.dart';
import '../../../../data/models/status.dart';
import '../../../../data/models/status_change.dart';
import '../../../../data/models/user.dart';
import '../../../../generated/l10n.dart';
import '../../../../utils/message.dart';
import '../../../common_blocs/status/status_bloc.dart';
import '../../user/bloc/user_bloc.dart';
import '../bloc/offer/offer_bloc.dart';
import '../bloc/price/price_bloc.dart';
import '../edit/edit_form_widget.dart';
import '../offer_screen_const.dart';
import '../offer_widget/offer_pdf_view_button_widget.dart';
import 'footer.dart';

Widget tableSearch(
  double min,
  double max,
  double maxWidth,
  BuildContext context,
) {
  final listOffersFormKey = GlobalKey<FormBuilderState>();

  return Padding(
    padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
    child: FormBuilder(
      key: listOffersFormKey,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          verticalDirection: VerticalDirection.up,
          children: <Widget>[
            SizedBox(
              height: 60,
              width: 300,
              child: searchListButton(context, listOffersFormKey: listOffersFormKey),
            ),
            SizedBox(width: 20),
            Column(
              children: [
                SizedBox(
                  height: 60,
                  width: 300,
                  child: BlocBuilder<UserBloc, UserState>(
                    builder: (context, state) {
                      if (state is UserListSuccessState) {
                        List<User> userList = state.userList;
                        if (state.userList[0].id != 0) state.userList.insert(0, User(id: 0, firstName: "Tümü", lastName: " "));
                        return FormBuilderDropdown(
                          name: 'offerListUser',
                          decoration: InputDecoration(
                            labelText: S.of(context).plasiyer,
                          ),
                          items: userList
                              .map(
                                (userList) => DropdownMenuItem(
                                  value: userList,
                                  child: Text("${userList.firstName == null ? "" : userList.firstName?.capitalize()} "
                                      "${userList.lastName == null ? "" : userList.lastName?.capitalize()}"),
                                ),
                              )
                              .toList(),
                          initialValue: userList[0],
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 60,
                  width: 300,
                  child: FormBuilderDateRangePicker(
                    name: 'offerListDate',
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                    initialValue: DateTimeRange(
                      start: DateTime.now().subtract(Duration(days: 7)),
                      end: DateTime.now(),
                    ),
                    initialEntryMode: DatePickerEntryMode.input,
                    format: DateFormat('  dd-MM-yyyy  '),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      labelText: S.of(context).date,
                    ),
                    onChanged: (value) {

                      var endtDateTime = value!.end;
                      endtDateTime = endtDateTime.add(Duration(hours: 23, minutes: 59));

                      ConstOfferStationMaturity.startDate = "${value!.start.toIso8601String().replaceAll(":", "%3A")}Z";
                      ConstOfferStationMaturity.endDate = "${endtDateTime.toIso8601String().replaceAll(":", "%3A")}Z";
                    },
                    autofocus: false,
                    allowClear: true,
                    autocorrect: true,
                  ),
                ),
              ],
            ),
            SizedBox(width: 20),
            Row(
              children: [
                SizedBox(
                  height: 180,
                  width: 160,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        FormBuilderCheckbox(
                          contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          name: 'offerListApprovedStatus',
                          initialValue: false,
                          title: Text(S.of(context).approved_status),
                          onChanged: (value) {
                            ConstOfferStationMaturity.approvedOfferSelectedValue = value!;
                          },
                        ),
                        FormBuilderCheckbox(
                          contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          name: 'offerListConfirmationStatus',
                          initialValue: false,
                          title: Text(S.of(context).confirmation_status),
                          onChanged: (value) {
                            ConstOfferStationMaturity.confirmationOfferSelectedValue = value!;
                          },
                        ),
                        FormBuilderCheckbox(
                          contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          name: 'offerListCompletedStatus',
                          initialValue: false,
                          title: Text(S.of(context).completed_status),
                          onChanged: (value) {
                            ConstOfferStationMaturity.completedOfferSelectedValue = value!;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 180,
                  width: 160,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: SizedBox(
                      height: 120,
                      child: Column(
                        children: [
                          FormBuilderCheckbox(
                            contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                            name: 'offerListCalculatedStatus',
                            initialValue: false,
                            title: Text(S.of(context).calculated_status),
                            onChanged: (value) {
                              ConstOfferStationMaturity.calculatedOfferSelectedValue = value!;
                            },
                          ),
                          FormBuilderCheckbox(
                            contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                            name: 'offerListCancelledStatus',
                            initialValue: false,
                            title: Text(S.of(context).cancelled_status),
                            onChanged: (value) {
                              ConstOfferStationMaturity.cancelledOfferSelectedValue = value!;
                            },
                          ),
                          FormBuilderCheckbox(
                            contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                            name: 'offerListRejectStatus',
                            initialValue: false,
                            title: Text(S.of(context).rejected_status),
                            onChanged: (value) {
                              ConstOfferStationMaturity.rejectOfferSelectedValue = value!;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

searchListButton(BuildContext context, {GlobalKey<FormBuilderState>? listOffersFormKey}) {
  return SizedBox(
    height: 40,
    width: 200,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Text(S.of(context).list),
      onPressed: () {
        if (listOffersFormKey!.currentState!.saveAndValidate()) {
          BlocProvider.of<OfferBloc>(context).add(
            OfferSearch(
              startDateTime: ConstOfferStationMaturity.startDate,
              endDateTime: ConstOfferStationMaturity.endDate,
              limit: 10,
              startIndex: 0,
              user: listOffersFormKey.currentState?.fields['offerListUser']?.value,
            ),
          );
        }
      },
    ),
  );
}

Padding tableHeader(BuildContext context) {
  return Padding(
    padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      verticalDirection: VerticalDirection.down,
      children: [
        Expanded(flex: 5, child: Text(S.of(context).date, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 15, child: Text(S.of(context).customer, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 6, child: Text(S.of(context).plasiyer, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 8, child: Text(S.of(context).status, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 6, child: Text(S.of(context).corporation, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 7, child: Text(S.of(context).destination_address, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 5, child: Text(S.of(context).transport_cost_tl, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 5, child: Text(S.of(context).birim, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 5, child: Text(S.of(context).maturity, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 5, child: Text(S.of(context).unit_price, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 5, child: Text(S.of(context).increase, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 5, child: Text(S.of(context).increase_unit_price, textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
        SizedBox(width: 5),
        Expanded(flex: 5, child: Text(" ", textAlign: TextAlign.left, style: TextStyle(fontSize: 10))),
      ],
    ),
  );
}

BlocBuilder<OfferBloc, OfferState> tableList() {
  return BlocBuilder<OfferBloc, OfferState>(
    builder: (context, state) {
      if (state is OfferSearchInitialState) {
        return Center(child: CircularProgressIndicator());
      }
      if (state is OfferSearchSuccessState) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            ListView.builder(
              itemCount: state.offer.length,
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
                DateTime parseDate = DateFormat("yyyy-MM-dd").parse(state.offer[index].createdDate!);
                var inputDate = DateTime.parse(parseDate.toString());
                var outputFormat = DateFormat('dd/MM/yyyy');
                var outputDate = outputFormat.format(inputDate);

                return Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                  child: Container(
                    height: 50,
                    decoration: buildTableRowDecoration(index, context),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      verticalDirection: VerticalDirection.down,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text("  $outputDate", textAlign: TextAlign.left, style: TextStyle(fontSize: 10)),
                        ),
                        Expanded(
                          flex: 15,
                          child: Text(state.offer[index].customer?.name.toString() ?? "",
                              textAlign: TextAlign.left, style: TextStyle(fontSize: 10)),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 6,
                          child: Text("${state.offer[index].user?.firstName.toString()} ${state.offer[index].user?.lastName.toString()}",
                              textAlign: TextAlign.left, style: TextStyle(fontSize: 10)),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 8,
                          child: Text(S.of(context).translate_status_title(state.offer[index].status?.name ?? ""),
                              textAlign: TextAlign.left, style: TextStyle(fontSize: 10)),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${state.offer[index].corporation?.name.toString()}",
                                  textAlign: TextAlign.left, style: TextStyle(fontSize: 10)),
                              SizedBox(height: 5),
                              Text("${state.offer[index].station?.name.toString()}",
                                  textAlign: TextAlign.left, style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 7,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${state.offer[index].destinationCity?.name.toString()}",
                                  textAlign: TextAlign.left, style: TextStyle(fontSize: 10)),
                              SizedBox(height: 5),
                              Text("${state.offer[index].destinationDistrict?.name.toString()}",
                                  textAlign: TextAlign.left, style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 5,
                          child: Text(
                              "${NumberFormat.currency(locale: 'tr_TR', decimalDigits: 0, symbol: "").format(int.parse(state.offer[index].transportCost.toString()))} ₺",
                              style: TextStyle(fontSize: 10),
                              textAlign: TextAlign.left),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 5,
                          child: Text(
                              "${NumberFormat.currency(locale: 'tr_TR', decimalDigits: 0, symbol: "").format(int.parse(state.offer[index].liter.toString()))} Lt",
                              style: TextStyle(fontSize: 10),
                              textAlign: TextAlign.left),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 5,
                          child: Text(
                              state.offer[index].maturity.toString() == "-1"
                                  ? S.of(context).credit_card
                                  : "${state.offer[index].maturity} ${S.of(context).day}",
                              style: TextStyle(fontSize: 10),
                              textAlign: TextAlign.left),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 5,
                          child: Text("${((state.offer[index].unitPrice ?? 0.0)).toStringAsFixed(2).toString().replaceAll(".", ",")} ₺",
                              style: TextStyle(fontSize: 10), textAlign: TextAlign.left),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 5,
                          child: Text("${((state.offer[index].increase ?? 0.0)).toStringAsFixed(2).toString().replaceAll(".", ",")} ₺",
                              style: TextStyle(fontSize: 10), textAlign: TextAlign.left),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 5,
                          child: Text("${((state.offer[index].totalPrice ?? 0.0)).toStringAsFixed(2).toString().replaceAll(".", ",")} ₺",
                              style: TextStyle(fontSize: 10), textAlign: TextAlign.left),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 5,
                          child: IconButton(
                            alignment: Alignment.centerRight,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            icon: Icon(
                              Icons.edit,
                              shadows: const [
                                Shadow(
                                  color: Colors.grey,
                                  offset: Offset(1, 1),
                                  blurRadius: 1,
                                ),
                              ],
                            ),
                            onPressed: () {
                              offerEditFormScreen(context, state.offer[index], state.offer[index].customer, state.offer[index].status);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            OfferListFooterWidget(state: state),
          ],
        );
      }
      if (state is OfferSearchFailureState) {
        return Center(child: Text("Teklif bulunamadı"));
      }
      return Container();
    },
  );
}

BoxDecoration buildTableRowDecoration(int index, BuildContext context) {
  // dark or light mode row decoration
  if (Theme.of(context).brightness == Brightness.dark) {
    if (index % 2 == 0) {
      return BoxDecoration(color: Colors.black26);
    } else {
      return BoxDecoration();
    }
  } else {
    if (index % 2 == 0) {
      return BoxDecoration(color: Colors.blueGrey[50]);
    } else {
      return BoxDecoration();
    }
  }
}

class OfferChangeStatusFormDropDownWidget extends StatelessWidget {
  final GlobalKey<FormBuilderState> eoStatus;
  final GlobalKey<FormBuilderState> eoPrice;
  final double increase;
  final Status? oldStatus;
  final Offer offer;
  final Customer customer;

  const OfferChangeStatusFormDropDownWidget({
    super.key,
    required this.increase,
    this.oldStatus,
    required this.eoStatus,
    required this.offer,
    required this.eoPrice,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatusBloc, StatusState>(
      builder: (context, state) {
        if (state is StatusWithOfferInitialState) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is StatusWithOfferLoadSuccessState) {
          return state.statusList.isNotEmpty
              ? Column(
                  children: [
                    Column(
                      children: [
                        SizedBox(height: 10),
                        AppConstants.role == "ROLE_ADMIN"
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 0),
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
                                            child: Text(S.of(context).unit_price_update, style: TextStyle(fontSize: 12)),
                                            onPressed: () {
                                              if (eoPrice.currentState!.saveAndValidate()) {
                                                if (offer.totalPrice != eoPrice.currentState!.value['eoPrice']) {
                                                  String newTotalPrice = eoPrice.currentState!.value['eoPrice'];
                                                  newTotalPrice = newTotalPrice.replaceAll(",", ".");
                                                  BlocProvider.of<OfferBloc>(context).add(
                                                    OfferUpdateDescription(
                                                      offer: Offer(
                                                        id: offer.id,
                                                        offeringType: offer.offeringType,
                                                        description: eoPrice.currentState!.value['description'],
                                                        rate: offer.rate,
                                                        active: offer.active,
                                                        completed: offer.completed,
                                                        maturity: offer.maturity,
                                                        liter: offer.liter,
                                                        unitPrice: offer.unitPrice,
                                                        totalPrice: double.parse(newTotalPrice),
                                                      ),
                                                    ),
                                                  );
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
                                    child: BlocBuilder<PriceBloc, PriceState>(
                                      builder: (context, state) {
                                        return Container(
                                          decoration: backColor(context),
                                          child: FormBuilder(
                                            key: eoPrice,
                                            child: FormBuilderTextField(
                                              name: 'eoPrice',
                                              initialValue: offer.totalPrice?.toStringAsFixed(2).toString().replaceAll(".", ","),
                                              style: TextStyle(fontSize: 16),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                                border: InputBorder.none,
                                              ),
                                              onChanged: (value) {},
                                              keyboardType: TextInputType.number,
                                              validator: FormBuilderValidators.compose([
                                                FormBuilderValidators.required(errorText: S.of(context).required_cost),
                                              ]),
                                            ),
                                          ),
                                        );
                                      },
                                      buildWhen: (previous, current) {
                                        if (current is PriceUpdatedInitial) {
                                          Message.getMessage(context: context, title: "Güncelleniyor...", content: "");
                                        }
                                        if (current is PriceUpdatedSuccess) {
                                          Message.getMessage(context: context, title: "Başarıyla güncellendi.", content: "");
                                        }
                                        if (current is PriceUpdatedFailure) {
                                          Message.errorMessage(context: context, title: "Güncellenemedi.", content: "");
                                        }
                                        return true;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 0),
                                ],
                              )
                            : RowWidget(
                                title: S.of(context).increase_unit_price,
                                content: ("${offer.totalPrice?.toStringAsFixed(2).toString().replaceAll(".", ",")} ₺")),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            S.of(context).status,
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        SizedBox(width: 50),
                        Expanded(
                          flex: 3,
                          child: FormBuilder(
                            key: eoStatus,
                            child: FormBuilderDropdown(
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                border: InputBorder.none,
                              ),
                              name: 'eoStatus',
                              items: state.statusList.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(S.of(context).translate_status_title(status.name ?? ""), style: TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              initialValue: state.statusList[0],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              width: 100,
                              child: pdfOpenButton(customer, [offer], "PDF", context),
                            ),
                          ],
                        ),
                        SizedBox(width: 10),
                        BlocBuilder<OfferBloc, OfferState>(
                          builder: (context, state) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    child: Text(S.of(context).update),
                                    onPressed: () {
                                      if (eoStatus.currentState!.saveAndValidate()) {
                                        BlocProvider.of<OfferBloc>(context).add(
                                          OfferStatusUpdate(
                                            statusChange: StatusChange(
                                                offeringId: offer.id!,
                                                statusId: eoStatus.currentState?.fields['eoStatus']?.value.id,
                                                comment: "Status değişikliği yapıldı."),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                          buildWhen: (previous, current) {
                            if (current is OfferStatusUpdateInitialState ||
                                current is OfferUpdateInitialState ||
                                current is OfferUpdateOfferDescriptionInitialState) {
                              Message.getMessage(title: "Güncelleniyor...", context: context, content: "");
                            }
                            if (current is OfferStatusUpdateSuccessState ||
                                current is OfferUpdateSuccessState ||
                                current is OfferUpdateOfferDescriptionSuccessState) {
                              Message.getMessage(title: "Başarıyla güncellendi.", context: context, content: "");
                            }
                            if (current is OfferStatusUpdateFailureState ||
                                current is OfferUpdateFailureState ||
                                current is OfferUpdateOfferDescriptionFailureState) {
                              Message.errorMessage(title: "Güncellenemedi.", context: context, content: "");
                            }
                            return true;
                          },
                        ),
                        SizedBox(width: 10),
                        Column(
                          children: [
                            SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Text(S.of(context).exit),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              : BlocBuilder<OfferBloc, OfferState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RowWidget(
                            title: S.of(context).increase_unit_price,
                            content: ("${offer.totalPrice?.toStringAsFixed(2).toString().replaceAll(".", ",")} ₺")),
                        SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                S.of(context).status,
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            SizedBox(width: 50),
                            Expanded(
                              flex: 3,
                              child: Text(oldStatus?.description.toString() ?? "-", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: pdfOpenButton(customer, [offer], "PDF", context),
                                ),
                              ],
                            ),
                            SizedBox(width: 10),
                            Column(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    child: Text(S.of(context).exit),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  buildWhen: (previous, current) {
                    if (current is OfferStatusUpdateInitialState ||
                        current is OfferUpdateInitialState ||
                        current is OfferUpdateOfferDescriptionInitialState) {
                      Message.getMessage(title: "Güncelleniyor...", context: context, content: "");
                    }
                    if (current is OfferStatusUpdateSuccessState ||
                        current is OfferUpdateSuccessState ||
                        current is OfferUpdateOfferDescriptionSuccessState) {
                      Message.getMessage(title: "Başarıyla güncellendi.", context: context, content: "");
                    }
                    if (current is OfferStatusUpdateFailureState ||
                        current is OfferUpdateFailureState ||
                        current is OfferUpdateOfferDescriptionFailureState) {
                      Message.errorMessage(title: "Güncellenemedi.", context: context, content: "");
                    }
                    return true;
                  },
                );
        }
        if (state is StatusWithOfferLoadFailureState) {
          return Center(child: Text("Yüklenirken bir hata oluştu."));
        }
        return Container();
      },
    );
  }
}
