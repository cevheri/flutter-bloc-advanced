import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../data/models/station.dart';
import '../../../../generated/l10n.dart';
import '../../../../utils/message.dart';
import '../../../common_blocs/city/city_bloc.dart';
import '../../corporation/bloc/corporation_bloc.dart';
import '../../station/bloc/station_bloc.dart';

class StationEditFormCorporation extends StatelessWidget {
  final Station station;

  const StationEditFormCorporation({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CorporationBloc, CorporationState>(
      builder: (context, state) {
        if (state is CorporationListSuccessState) {
          return FormBuilderDropdown(
            name: 'seCorporation',
            decoration: InputDecoration(
              labelText: S.of(context).corporations,
            ),
            items: state.corporationList
                .map(
                  (corporation) => DropdownMenuItem(
                    value: corporation,
                    child: Text(corporation.name ?? ""),
                  ),
                )
                .toList(),
            initialValue: station.corporation,
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class StationEditFormName extends StatelessWidget {
  final Station station;

  const StationEditFormName({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'seName',
      decoration: InputDecoration(
        labelText: S.of(context).name,
      ),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).name_required),
      ]),
      initialValue: station.name,
    );
  }
}

class StationEditFormCity extends StatelessWidget {
  final Station station;

  const StationEditFormCity({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CityBloc, CityState>(
      builder: (context, state) {
        if (state is CityLoadSuccessState) {
          return FormBuilderDropdown(
            name: 'seCityId',
            decoration: InputDecoration(
              labelText: S.of(context).city,
            ),
            items: state.city
                .map(
                  (city) => DropdownMenuItem(
                    value: city,
                    child: Text(city.name ?? ""),
                  ),
                )
                .toList(),
            initialValue: station.city,
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class StationEditFormActive extends StatelessWidget {
  final Station station;

  const StationEditFormActive({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return FormBuilderSwitch(
      contentPadding: EdgeInsets.all(0),
      decoration: InputDecoration(),
      name: 'seActive',
      title: Text(S.of(context).active),
      initialValue: station.active,
    );
  }
}

class StationEditSubmitButton extends StatelessWidget {
  final Station station;
  final GlobalKey<FormBuilderState>? stationEditFormKey;

  const StationEditSubmitButton(BuildContext context, {super.key, required this.stationEditFormKey, required this.station});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationBloc, StationState>(
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            child: Text(S.of(context).edit_station),
            onPressed: () {
              if (stationEditFormKey!.currentState!.saveAndValidate()) {
                Station cachedStation = Station(
                  id: station.id,
                  corporation: station.corporation,
                  name: station.name,
                  city: station.city,
                  active: station.active,
                );
                Station stationEdit = Station(
                  id: station.id,
                  corporation: stationEditFormKey!.currentState!.fields['seCorporation']?.value ?? "",
                  name: stationEditFormKey!.currentState!.fields['seName']?.value ?? "",
                  city: stationEditFormKey!.currentState!.fields['seCityId']?.value ?? "",
                  active: stationEditFormKey!.currentState!.fields['seActive']?.value ?? "",
                );

                if (cachedStation != stationEdit) {
                  BlocProvider.of<StationBloc>(context).add(StationUpdate(station: stationEdit));
                } else {
                  Message.getMessage(context: context, title: "Değişiklik Bulunamadı", content: "");
                }
              }
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is StationUpdateInitialState) {
          Message.getMessage(context: context, title: "Kayıt Güncelleniyor", content: "");
        }
        if (current is StationUpdateSuccessState) {
          Message.getMessage(context: context, title: "Kayıt Güncellendi", content: "");
          Navigator.pop(context);
        }
        if (current is StationUpdateFailureState) {
          Message.errorMessage(title: 'Kayıt Güncellenemedi.', context: context,content: "");
        }
        return true;
      },
    );
  }
}
