import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../data/models/city.dart';
import '../../../../data/models/corporation.dart';
import '../../../../data/models/district.dart';
import '../../../../data/models/station.dart';
import '../../../../generated/l10n.dart';
import '../../../../utils/message.dart';
import '../../../common_blocs/city/city_bloc.dart';
import '../../../common_blocs/district/district_bloc.dart';
import '../../corporation/bloc/corporation_bloc.dart';
import '../bloc/station_bloc.dart';

class StationCreateFormSelectCorporation extends StatelessWidget {
  final GlobalKey<FormBuilderState>? stationFormKey;

  const StationCreateFormSelectCorporation({super.key, required this.stationFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CorporationBloc, CorporationState>(
      builder: (context, state) {
        if (state is CorporationListSuccessState) {
          return FormBuilderDropdown(
            name: 'createFormStationCorporation',
            decoration: InputDecoration(
              labelText: S.of(context).corporations,
            ),
            items: state.corporationList.map((corporation) {
              return DropdownMenuItem(
                value: corporation,
                child: Text(corporation.name!),
              );
            }).toList(),
          );
        }
        return Container();
      },
    );
  }
}

class StationCreateFormSelectCity extends StatelessWidget {
  final GlobalKey<FormBuilderState>? stationFormKey;

  const StationCreateFormSelectCity({super.key, required this.stationFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CityBloc, CityState>(
      builder: (context, state) {
        if (state is CityLoadSuccessState) {
          return FormBuilderDropdown(
            name: 'createFormStationCity',
            decoration: InputDecoration(
              labelText: S.of(context).cities,
            ),
            items: state.city.map((station) {
              return DropdownMenuItem(
                value: station,
                child: Text(station.name!),
              );
            }).toList(),
            onChanged: (value) {
              BlocProvider.of<DistrictBloc>(context).add(DistrictLoadList(districtId: value!.id.toString()));
            },
          );
        }
        return Container();
      },
    );
  }
}

class StationCreateFormSelectDistrict extends StatelessWidget {
  final GlobalKey<FormBuilderState>? stationFormKey;

  const StationCreateFormSelectDistrict({super.key, required this.stationFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DistrictBloc, DistrictState>(
      builder: (context, state) {
        if (state is DistrictLoadSuccessState) {
          return FormBuilderDropdown(
            name: 'createFormStationDistrict',
            decoration: InputDecoration(
              labelText: S.of(context).districts,
            ),
            items: state.district.map((station) {
              return DropdownMenuItem(
                value: station,
                child: Text(station.name ?? ""),
              );
            }).toList(),
          );
        }
        return Container();
      },
    );
  }
}

class StationCreateFormName extends StatelessWidget {
  final GlobalKey<FormBuilderState>? stationFormKey;

  const StationCreateFormName({super.key, required this.stationFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'createFormStationName',
      decoration: InputDecoration(
        labelText: S.of(context).name,
      ),
      validator: FormBuilderValidators.compose(
        [
          FormBuilderValidators.minLength(errorText: S.of(context).name_min_length, 1),
          FormBuilderValidators.maxLength(errorText: S.of(context).name_max_length, 50),
        ],
      ),
    );
  }
}

class StationCreateFormActive extends StatelessWidget {
  final GlobalKey<FormBuilderState>? stationFormKey;

  const StationCreateFormActive({super.key, required this.stationFormKey});

  @override
  Widget build(BuildContext context) {
    return FormBuilderSwitch(
      name: 'createFormStationActive',
      initialValue: true,
      title: Text(S.of(context).active),
    );
  }
}

class StationCreateFormSubmitButton extends StatelessWidget {
  final GlobalKey<FormBuilderState>? createStationFormKey;

  const StationCreateFormSubmitButton(BuildContext context, {super.key, required this.createStationFormKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationBloc, StationState>(
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            child: Text(S.of(context).create_station),
            onPressed: () {
              if (createStationFormKey!.currentState!.saveAndValidate()) {
                Station station = Station(
                  name: createStationFormKey!.currentState!.fields['createFormStationName']!.value,
                  active: createStationFormKey!.currentState!.fields['createFormStationActive']!.value,
                  corporation: Corporation(
                    id: createStationFormKey!.currentState!.fields['createFormStationCorporation']!.value.id,
                    name: createStationFormKey!.currentState!.fields['createFormStationCorporation']!.value.name,
                  ),
                  city: City(
                    id: createStationFormKey!.currentState!.fields['createFormStationCity']!.value.id,
                    name: createStationFormKey!.currentState!.fields['createFormStationCity']!.value.name,
                  ),
                  district: District(
                    id: createStationFormKey!.currentState!.fields['createFormStationDistrict']!.value.id,
                    name: createStationFormKey!.currentState!.fields['createFormStationDistrict']!.value.name,
                  ),
                );
                BlocProvider.of<StationBloc>(context).add(StationCreate(station: station));
              }
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is StationCreateInitialState) {
          Message.getMessage(context: context, title: "Kayıt Oluşturuluyor",content: "");
        }
        if (current is StationCreateSuccessState) {
          Message.getMessage(context: context, title: "Kayıt Oluşturuldu",content: "");
          Navigator.pop(context);
        }
        if (current is StationCreateFailureState) {
          Message.errorMessage(title: 'Kayıt Oluşturulamadı.', context: context,content: "");
        }

        return true;
      },
    );
  }
}
