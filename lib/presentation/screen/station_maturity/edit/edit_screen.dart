import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../../../../data/models/station.dart';
import '../bloc/station_maturity_bloc.dart';
import 'edit_form_widget.dart';

class EditStationMaturityScreen extends StatelessWidget {
  final Station station;

  EditStationMaturityScreen({required this.station})
      : super(key: ApplicationKeys.listStationsScreen);
  final stationMaturityEditFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<StationMaturityBloc>(context)
        .add(StationMaturityLoad(id: station.id!));
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).edit_station_maturity),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return layoutBody(context, 200, 1100, constraints.maxWidth);
          } else if (constraints.maxWidth > 700 && constraints.maxWidth < 900) {
            return layoutBody(context, 200, 1200, constraints.maxWidth);
          } else {
            return Center(
              child: Text(S.of(context).screen_size_error),
            );
          }
        },
      ),
    );
  }

  Widget layoutBody(
      BuildContext context, double min, double max, double maxWidth) {
    return FormBuilder(
      key: stationMaturityEditFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          StationMaturityEditForm(station: station, formKey: stationMaturityEditFormKey),
        ],
      ),
    );
  }

  Padding _tableHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(S.of(context).id, textAlign: TextAlign.center),
          ),
          Expanded(
            child:
                Text(S.of(context).corporations, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(S.of(context).name, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(S.of(context).maturity, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(S.of(context).rate, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(""),
          ),
          Expanded(
            child: Text(""),
          ),
        ],
      ),
    );
  }

  /*
  Container _buildStationDetail(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 300, maxWidth: 700),
      padding: EdgeInsets.all(10),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(station.id.toString(), textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text(station.corporation?.name ?? "",
                    textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text(station.name ?? "", textAlign: TextAlign.center),
              ),
              Expanded(
                child:
                    Text(station.city?.name ?? "", textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text(station.active.toString(),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }

   */
}
