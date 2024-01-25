import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../../../common_blocs/city/city_bloc.dart';
import '../../corporation/bloc/corporation_bloc.dart';
import 'create_form_field_widget.dart';

class CreateStationScreen extends StatelessWidget {
  CreateStationScreen() : super(key: ApplicationKeys.createStationScreen);
  final createStationFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<CorporationBloc>(context).add(CorporationLoadList());
    BlocProvider.of<CityBloc>(context).add(CityLoadList());
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).create_station),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  _buildBody(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minWidth: 300, maxWidth: 700),
          padding: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: FormBuilder(
            key: createStationFormKey,
            child: Column(
              children: <Widget>[
                StationCreateFormSelectCorporation(stationFormKey: createStationFormKey),
                StationCreateFormSelectCity(stationFormKey: createStationFormKey),
                StationCreateFormSelectDistrict(stationFormKey: createStationFormKey),
                StationCreateFormName(stationFormKey: createStationFormKey),
                StationCreateFormActive(stationFormKey: createStationFormKey),
                SizedBox(height: 20),
                StationCreateFormSubmitButton(context, createStationFormKey: createStationFormKey)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
