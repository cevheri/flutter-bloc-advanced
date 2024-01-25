import 'package:flutter_bloc_advance/data/models/customer.dart';
import 'package:flutter_bloc_advance/data/models/city.dart';
import 'package:flutter_bloc_advance/data/models/status.dart';
import 'package:flutter_bloc_advance/presentation/screen/corporation_maturity/bloc/corporation_maturity.dart';
import 'package:flutter_bloc_advance/presentation/screen/station_maturity/bloc/station_maturity.dart';
import 'package:flutter_bloc_advance/utils/app_constants.dart';
import 'package:flutter_bloc_advance/utils/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:pattern_formatter/numeric_formatter.dart';

import '../../../../data/models/district.dart';
import '../../../../data/models/offer.dart';
import '../../../../generated/l10n.dart';
import '../../../common_blocs/city/city_bloc.dart';
import '../../../common_blocs/district/district_bloc.dart';
import '../../corporation/bloc/corporation_bloc.dart';
import '../../refinery/bloc/refinery_bloc.dart';
import '../../station/bloc/station_bloc.dart';
import '../bloc/offer/offer_bloc.dart';
import 'create_offer_view_detail_screen.dart';
import '../offer_screen_const.dart';

Widget customerDetailTable(BuildContext context, Customer customer) {
  final headerStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(S.of(context).name,
                textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(S.of(context).vat_no,
                textAlign: TextAlign.left, style: headerStyle),
          ),
        ],
      ),
      SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(customer.name.toString(), textAlign: TextAlign.left),
          ),
          Expanded(
            flex: 2,
            child: Text(customer.vatNo ?? "-", textAlign: TextAlign.left),
          ),
        ],
      ),
      SizedBox(height: 30),
    ],
  );
}

/// Create Offer Form Field Widget
class OfferCreateFormSelectRefinery extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormSelectRefinery(
      {super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RefineryBloc, RefineryState>(
      builder: (context, state) {
        if (state is RefineryFindInitialState) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is RefinerySearchSuccessState) {
          return Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: FormBuilderDropdown(
              name: 'offerCreateFormSelectRefinery',
              decoration: InputDecoration(
                labelText: S.of(context).refineries,
              ),
              items: state.refineryList.map((refinery) {
                return DropdownMenuItem(
                  value: refinery,
                  child: Text(refinery.name.toString()),
                );
              }).toList(),
              validator: FormBuilderValidators.compose(
                [
                  FormBuilderValidators.required(
                      errorText: S.of(context).refinery_required),
                ],
              ),
              onChanged: (value) {
                ConstOfferStationMaturity.refinery = value!;
              },
            ),
          );
        }
        if (state is RefinerySearchFailureState) {
          return Center(child: Text("Yüklenirken bir hata oluştu."));
        }
        return Container();
      },
    );
  }
}

//offerCreateFormSelectCorporation
class OfferCreateFormSelectCorporation extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormSelectCorporation(
      {super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CorporationBloc, CorporationState>(
      builder: (context, state) {
        if (state is CorporationListInitialState) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is CorporationListSuccessState) {
          return Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: FormBuilderDropdown(
              name: 'offerCreateFormSelectCorporation',
              decoration: InputDecoration(
                labelText: S.of(context).corporations,
              ),
              items: state.corporationList.map((corporation) {
                return DropdownMenuItem(
                  value: corporation,
                  child: Text(corporation.name!),
                );
              }).toList(),
              onChanged: (value) {
                ConstOfferStationMaturity.corporation = value!;
                BlocProvider.of<CorporationMaturityBloc>(context)
                    .add(CorporationMaturityLoad(id: value.id!));
                ConstOfferStationMaturity.selectCorporationId = value.id!;
              },
              validator: FormBuilderValidators.compose(
                [
                  FormBuilderValidators.required(
                      errorText: S.of(context).corporation_required),
                ],
              ),
            ),
          );
        }
        if (state is CorporationListFailureState) {
          return Center(child: Text("Yüklenirken bir hata oluştu."));
        }
        return Container();
      },
    );
  }
}

//offerCreateFormSelectStation
class OfferCreateFormSelectStation extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormSelectStation(
      {super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationBloc, StationState>(
      builder: (context, state) {
        if (state is StationListWithCorporationInitialState) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is StationListWithCorporationSuccessState) {
          return Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: FormBuilderDropdown(
              name: 'offerCreateFormSelectStation',
              decoration: InputDecoration(
                labelText: S.of(context).stations,
              ),
              items: state.stationList.map((station) {
                return DropdownMenuItem(
                  value: station,
                  child: Text(station.name!),
                );
              }).toList(),
              onChanged: (value) {
                ConstOfferStationMaturity.station = value!;
                BlocProvider.of<StationMaturityBloc>(context)
                    .add(StationMaturityLoad(id: value.id!));
              },
              validator: FormBuilderValidators.compose(
                [
                  FormBuilderValidators.required(
                      errorText: S.of(context).station_required),
                ],
              ),
            ),
          );
        }
        if (state is StationListWithCorporationFailureState) {
          return Center(child: Text("Yüklenirken bir hata oluştu."));
        }
        return Container();
      },
    );
  }
}

//offerCreateFormSelectCity
class OfferCreateFormSelectCity extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormSelectCity(
      {super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CityBloc, CityState>(
      builder: (context, state) {
        if (state is CityInitialState) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is CityLoadSuccessState) {
          return Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: FormBuilderDropdown(
              name: 'offerCreateFormSelectCity',
              decoration: InputDecoration(
                labelText: S.of(context).destination_city,
              ),
              items: state.city.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city.name!),
                );
              }).toList(),
              onChanged: (value) {
                BlocProvider.of<DistrictBloc>(context)
                    .add(DistrictLoadList(districtId: value!.id.toString()));
              },
              validator: FormBuilderValidators.compose(
                [
                  FormBuilderValidators.required(
                      errorText: S.of(context).destination_city_required),
                ],
              ),
            ),
          );
        }
        if (state is CityLoadFailureState) {
          return Center(child: Text("Yüklenirken bir hata oluştu."));
        }
        return Container();
      },
    );
  }
}

//offerCreateFormSelectDistrict
class OfferCreateFormSelectDistrict extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormSelectDistrict(
      {super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DistrictBloc, DistrictState>(
      builder: (context, state) {
        if (state is DistrictInitialState) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is DistrictLoadSuccessState) {
          return Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: FormBuilderDropdown(
              name: 'offerCreateFormSelectDistrict',
              decoration: InputDecoration(
                labelText: S.of(context).destination_district,
              ),
              items: state.district.map((offer) {
                return DropdownMenuItem(
                  value: offer,
                  child: Text(offer.name ?? ""),
                );
              }).toList(),
            ),
          );
        }
        if (state is DistrictLoadFailureState) {
          return Center(child: Text("Yüklenirken bir hata oluştu."));
        }
        return Container();
      },
    );
  }
}

//offerCreateFormTransportDistance
class OfferCreateFormTransportDistance extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormTransportDistance(
      {super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: FormBuilderTextField(
        name: 'offerCreateFormTransportDistance',
        decoration: InputDecoration(
          labelText: S.of(context).transport_distance,
        ),
        validator: FormBuilderValidators.compose(
          [
            FormBuilderValidators.required(
                errorText: S.of(context).transport_distance_required),
            FormBuilderValidators.numeric(
                errorText: S.of(context).transport_distance_numeric),
          ],
        ),
        inputFormatters: [
          ThousandsFormatter(
              allowFraction: true,
              formatter: NumberFormat.currency(
                  locale: 'tr_TR', decimalDigits: 0, symbol: "")),
          CommaFormatter()
        ],
      ),
    );
  }
}

//offerCreateFormTransportCost
class OfferCreateFormTransportCost extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormTransportCost(
      {super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: FormBuilderTextField(
        name: 'offerCreateFormTransportCost',
        decoration: InputDecoration(
          labelText: S.of(context).transport_cost,
        ),
        inputFormatters: [
          ThousandsFormatter(
              allowFraction: true,
              formatter: NumberFormat.currency(
                  locale: 'tr_TR', decimalDigits: 0, symbol: "")),
          CommaFormatter()
        ],
        validator: FormBuilderValidators.compose(
          [
            FormBuilderValidators.required(
                errorText: S.of(context).transport_cost_required),
            FormBuilderValidators.numeric(
                errorText: S.of(context).transport_cost_numeric),
          ],
        ),
      ),
    );
  }
}

//offerCreateFormLitre
class OfferCreateFormLitre extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormLitre({super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: FormBuilderTextField(
        name: 'offerCreateFormLitre',
        decoration: InputDecoration(
          labelText: S.of(context).litre,
        ),
        validator: FormBuilderValidators.compose(
          [
            FormBuilderValidators.required(
                errorText: S.of(context).litre_required),
            FormBuilderValidators.numeric(
                errorText: S.of(context).litre_numeric),
          ],
        ),
        inputFormatters: [
          ThousandsFormatter(
              allowFraction: true,
              formatter: NumberFormat.currency(
                  locale: 'tr_TR', decimalDigits: 0, symbol: "")),
          CommaFormatter()
        ],
      ),
    );
  }
}

//offerCreateFormSelectCorporationMaturity
class OfferCreateFormSelectCorporationMaturity extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormSelectCorporationMaturity(
      {super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CorporationMaturityBloc, CorporationMaturityState>(
        builder: (context, state) {
      if (state is CorporationMaturityLoadInProgressState) {
        return Center(child: CircularProgressIndicator());
      }
      if (state is CorporationMaturityLoadSuccessState) {
        state.corporationMaturity
            .sort((a, b) => a.maturity!.compareTo(b.maturity!));
        return Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: FormBuilderCheckboxGroup(
            name: 'offerCreateFormSelectCorporationMaturity',
            decoration: InputDecoration(
              labelText: S.of(context).maturity,
            ),
            options: state.corporationMaturity.map(
              (corporationMaturity) {
                return FormBuilderFieldOption(
                  value: corporationMaturity,
                  child: Text(corporationMaturity.maturity.toString() == "-1"
                      ? S.of(context).credit_card
                      : "${corporationMaturity.maturity} ${S.of(context).day}"),
                );
              },
            ).toList(),
            validator: (value) {
              return value == null ? "Vade Seçiniz" : null;
            },
            onChanged: (value) {
              if (value != null) {
                print(value);
                ConstOfferStationMaturity.corporationMaturity = value;
                ConstOfferStationMaturity.corporationMaturity
                    .sort((a, b) => a.maturity!.compareTo(b.maturity!));
              }
            },
          ),
        );
      }
      if (state is CorporationMaturityLoadFailureState) {
        return Center(child: Text("Yüklenirken bir hata oluştu."));
      }
      return Container();
    }, buildWhen: (previous, current) {
      if (current is CorporationMaturityLoadSuccessState) {
        BlocProvider.of<StationBloc>(context).add(StationListWithCorporation(
            corporationId:
                ConstOfferStationMaturity.selectCorporationId.toString()));
        return true;
      }
      return false;
    });
  }
}

//offerCreateFormIncrease
class OfferCreateFormIncrease extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormIncrease({super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: FormBuilderTextField(
        name: 'offerCreateFormIncrease',
        decoration: InputDecoration(labelText: S.of(context).increase),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
      ),
    );
  }
}

//offerCreateFormDescription
class OfferCreateFormDescription extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormDescription(
      {super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: FormBuilderTextField(
        name: 'offerCreateFormDescription',
        decoration: InputDecoration(labelText: S.of(context).description_offer),
      ),
    );
  }
}

//offerCreateFormTransportDate
class OfferCreateFormTransportDate extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;

  const OfferCreateFormTransportDate(
      {super.key, required this.createOfferFormKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: FormBuilderDateTimePicker(
        name: 'offerCreateFormTransportDate',
        inputType: InputType.date,
        decoration: InputDecoration(labelText: S.of(context).transport_date),
        format: DateFormat("dd / MM / yyyy"),
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030),
        validator: FormBuilderValidators.compose(
          [
            FormBuilderValidators.required(
                errorText: S.of(context).transport_date_required),
          ],
        ),
      ),
    );
  }
}

class OfferCreateFormSubmitButton extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createOfferFormKey;
  final Customer customer;
  final headerStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  OfferCreateFormSubmitButton(BuildContext context,
      {super.key, required this.createOfferFormKey, required this.customer});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfferBloc, OfferState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: SizedBox(
            child: ElevatedButton(
              child: Text(S.of(context).calculate),
              onPressed: () {
                if (createOfferFormKey!.currentState!.saveAndValidate()) {
                  if (createOfferFormKey!
                          .currentState!
                          .fields['offerCreateFormSelectCorporationMaturity']!
                          .value ==
                      null) {
                    Message.errorMessage(
                        title: "Lütfen vade seçiniz.",
                        context: context,
                        content: "");
                    return;
                  }
                  List<Offer> offerList = [];
                  print(createOfferFormKey!
                      .currentState!.fields['offerCreateFormIncrease']?.value);
                  createOfferFormKey!.currentState!
                          .fields['offerCreateFormIncrease']?.value ??
                      0;
                  print(createOfferFormKey!
                      .currentState!.fields['offerCreateFormIncrease']?.value);

                  for (var i = 0;
                      i <
                          createOfferFormKey!
                              .currentState!
                              .fields[
                                  'offerCreateFormSelectCorporationMaturity']!
                              .value
                              .length;
                      i++) {
                    double increase = 0;
                    double quoteBidPrice = 0;
                    double refineryWithVat = createOfferFormKey!
                        .currentState!
                        .fields['offerCreateFormSelectRefinery']!
                        .value
                        .priceWithVat;
                    double corporationRate = createOfferFormKey!
                        .currentState!
                        .fields['offerCreateFormSelectCorporationMaturity']!
                        .value[i]
                        .rate;
                    int corporationMaturity = createOfferFormKey!
                        .currentState!
                        .fields['offerCreateFormSelectCorporationMaturity']!
                        .value[i]
                        .maturity;
                    String transportDistanceReplace = createOfferFormKey!
                        .currentState!
                        .fields['offerCreateFormTransportDistance']!
                        .value!
                        .replaceAll(".", "");
                    String transportCostReplace = createOfferFormKey!
                        .currentState!
                        .fields['offerCreateFormTransportCost']!
                        .value!
                        .replaceAll(".", "");
                    String literReplace = createOfferFormKey!
                        .currentState!.fields['offerCreateFormLitre']!.value!
                        .replaceAll(".", "");
                    increase = (double.parse(createOfferFormKey!.currentState!
                            .fields['offerCreateFormIncrease']?.value ??
                        "0"));
                    ConstOfferStationMaturity()
                        .stationRateCalc(corporationMaturity);
                    double quoteCost = refineryWithVat +
                        ((refineryWithVat *
                                ConstOfferStationMaturity.stationRate) /
                            100);
                    quoteBidPrice =
                        (quoteCost + ((quoteCost * corporationRate) / 100));
                    offerList.add(
                      Offer(
                        selectedCorporationMaturityDate:
                            ConstOfferStationMaturity.corporationMaturity[i],
                        selectedStationMaturityPrice:
                            ConstOfferStationMaturity.stationMaturity,
                        offeringType: "MARKETING",
                        active: true,
                        completed: false,
                        debt: 0,
                        credit: 0,
                        decrease: 0,
                        rate: 0,
                        status: Status(
                          id: 1,
                          name: "DRAFT",
                          description:
                              "Teklif koşulları başlatılmış ve kaydedilmiş, ancak onaylanmamış.",
                          orderPriority: 1,
                          active: true,
                        ),
                        customer: customer,
                        refinery: createOfferFormKey!.currentState!
                            .fields['offerCreateFormSelectRefinery']!.value,
                        corporation: createOfferFormKey!.currentState!
                            .fields['offerCreateFormSelectCorporation']!.value,
                        station: createOfferFormKey!.currentState!
                            .fields['offerCreateFormSelectStation']!.value,
                        destinationCity: buildCity(),
                        destinationDistrict: buildDistrict(),
                        transportDistance:
                            double.parse(transportDistanceReplace),
                        transportCost: double.parse(transportCostReplace),
                        liter: double.parse(literReplace),
                        maturity: createOfferFormKey!
                            .currentState!
                            .fields['offerCreateFormSelectCorporationMaturity']!
                            .value[i]
                            .maturity,
                        increase: increase,
                        description: createOfferFormKey!.currentState!
                            .fields['offerCreateFormDescription']?.value,
                        unitPrice: quoteBidPrice +
                            (double.parse(transportCostReplace) /
                                double.parse(literReplace)),
                        //shipmentDate: createOfferFormKey!.currentState!.fields['offerCreateFormTransportDate']!.value.toString(),
                        totalPrice: quoteBidPrice +
                            increase +
                            (double.parse(transportCostReplace) /
                                double.parse(literReplace)),
                      ),
                    );
                  }
                  BlocProvider.of<OfferBloc>(context)
                      .add(OfferCreate(offer: offerList));
                } else {
                  Message.errorMessage(
                      title: "Lütfen tüm alanları doldurunuz.",
                      context: context,
                      content: "");
                }
              },
            ),
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is OfferCreateInitialState) {
          Message.calculated(
              context: context,
              title: "Hesaplanıyor...",
              message: "Lütfen Bekleyiniz...",
              duration: (current.length * 3));
        }
        if (current is OfferCreateSuccessState) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EditOfferScreen(offer: current.offer, customer: customer),
            ),
          );
        }
        if (current is OfferCreateFailureState) {
          Message.errorMessage(
              title: 'Hesaplanamadı...', context: context, content: "");
        }
        if (current is OfferCreateSuccessState) {}
        if (current is OfferStatusUpdateInitialState) {
          Message.getMessage(
              context: context,
              title: "Teklif Oluşturuluyor",
              content: "Lütfen bekleyiniz...");
        }
        if (current is OfferStatusUpdateSuccessState) {
          Message.getMessage(
              context: context,
              title: "Teklif başarıyla oluşturuldu.",
              content: "Onay bekleniyor...");
        }
        if (current is OfferStatusUpdateFailureState) {
          Message.errorMessage(
              title: "Teklif oluşturulurken bir hata oluştu.",
              context: context,
              content: "");
        }
        return true;
      },
    );
  }

  District buildDistrict() {
    return District(
      id: createOfferFormKey!
          .currentState!.fields['offerCreateFormSelectDistrict']!.value.id,
      name: createOfferFormKey!
          .currentState!.fields['offerCreateFormSelectDistrict']!.value.name,
      code: createOfferFormKey!
          .currentState!.fields['offerCreateFormSelectDistrict']!.value.code,
    );
  }

  City buildCity() {
    return City(
        id: createOfferFormKey!
            .currentState!.fields['offerCreateFormSelectCity']!.value.id,
        name: createOfferFormKey!
            .currentState!.fields['offerCreateFormSelectCity']!.value.name,
        plateCode: createOfferFormKey!.currentState!
            .fields['offerCreateFormSelectCity']!.value.plateCode);
  }

  String capitalize(String s) {
    return "${s[0].toUpperCase()}${s.substring(1).toLowerCase()}";
  }
}
