import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../../../../data/models/station.dart';
import 'edit_form_widget.dart';

class EditStationScreen extends StatelessWidget {
  final Station station;

  EditStationScreen({required this.station})
      : super(key: ApplicationKeys.listStationsScreen);
  final stationEditFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).edit_station),
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
            key: stationEditFormKey,
            child: Column(
              children: <Widget>[
                StationEditFormCorporation(station: station),
                SizedBox(height: 20),
                StationEditFormName(station: station),
                SizedBox(height: 20),
                StationEditFormCity(station: station),
                SizedBox(height: 20),
                StationEditFormActive(station: station),
                SizedBox(height: 20),
                StationEditSubmitButton(context,
                    stationEditFormKey: stationEditFormKey,
                    station: station),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


