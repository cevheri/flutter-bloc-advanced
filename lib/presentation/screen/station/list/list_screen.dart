//ListStationScreen

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../../../../data/models/city.dart';
import '../../../../data/models/corporation.dart';
import '../../../common_blocs/city/city_bloc.dart';
import '../../corporation/bloc/corporation_bloc.dart';
import '../bloc/station_bloc.dart';
import '../edit/edit_screen.dart';

class ListStationsScreen extends StatelessWidget {
  ListStationsScreen() : super(key: ApplicationKeys.listStationsScreen);
  final listStationsFormKey = GlobalKey<FormBuilderState>();
  final headerStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<CorporationBloc>(context).add(CorporationSearch());
    BlocProvider.of<CityBloc>(context).add(CityLoadList());
    BlocProvider.of<StationBloc>(context)
        .add(StationSearch(corporationId: "0", cityId: "0"));

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).list_station),
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

  Column layoutBody(
      BuildContext context, double min, double max, double maxWidth) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        _tableSearch(min, max, maxWidth, context),
        SizedBox(height: 20),
        _tableHeader(context),
        BlocBuilder<StationBloc, StationState>(
          builder: (context, state) {
            if (state is StationListSuccessState) {
              return ListView.builder(
                itemCount: state.stationList.length,
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                    child: Container(
                      height: 50,
                      decoration: buildTableRowDecoration(index, context),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(state.stationList[index].id.toString(),
                                textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                                state.stationList[index].corporation?.name ??
                                    "",
                                textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(state.stationList[index].name ?? "",
                                textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                                state.stationList[index].city?.name ?? "",
                                textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 1,
                            child: buildActiveItem(state, index),
                          ),
                          Expanded(
                            flex: 1,
                            child: IconButton(
                              alignment: Alignment.centerRight,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditStationScreen(
                                      station: state.stationList[index],
                                    ),
                                  ),
                                ).then((value) {
                                  if (listStationsFormKey.currentState!
                                      .saveAndValidate()) {
                                    BlocProvider.of<StationBloc>(context)
                                        .add(StationSearch());
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else
              return Container();
          },
        ),
      ],
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

  Switch buildActiveItem(StationListSuccessState state, int index) {
    return Switch(
      value: state.stationList[index].active!,
      onChanged: (value) {
        // ignore: unnecessary_statements
        value;
      },
    );
  }

  Padding _tableHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(S.of(context).id,
                textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(S.of(context).corporations,
                textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(S.of(context).name,
                textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(S.of(context).cities,
                textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 1,
            child: Text(S.of(context).active, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 1,
            child: Text("", textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _tableSearch(
      double min, double max, double maxWidth, BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
      child: FormBuilder(
        key: listStationsFormKey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 10),
                child: BlocBuilder<CorporationBloc, CorporationState>(
                  builder: (context, state) {
                    if (state is CorporationListSuccessState) {
                      state.corporationList[0].id != 0
                          ? state.corporationList.insert(
                          0,
                          Corporation(
                            id: 0,
                            name: "Tümü",
                          ))
                          : null;
                      return FormBuilderDropdown(
                        alignment: Alignment.topRight,
                        name: 'slCorporationId',
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
                        initialValue: state.corporationList[0],
                      );
                    } else
                      return Container();
                  },
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 10),
                child: BlocBuilder<CityBloc, CityState>(
                  builder: (context, state) {
                    if (state is CityLoadSuccessState) {
                      state.city[0].id != 0
                          ? state.city.insert(
                          0,
                          City(
                            id: 0,
                            name: "Tümü",
                          ))
                          : null;
                      return FormBuilderDropdown(
                        name: 'slCityId',
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
                        initialValue: state.city[0],
                      );
                    } else
                      return Container();
                  },
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _submitListButton(context),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }

  _submitListButton(BuildContext context) {
    return Container(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Text(S.of(context).list),
        onPressed: () {
          if (listStationsFormKey.currentState!.saveAndValidate()) {
            BlocProvider.of<StationBloc>(context).add(
              StationSearch(
                corporationId: listStationsFormKey
                        .currentState?.fields['slCorporationId']?.value.id
                        .toString() ??
                    "0",
                cityId: listStationsFormKey
                        .currentState?.fields['slCityId']?.value.id
                        .toString() ??
                    "0",
              ),
            );
          }
        },
      ),
    );
  }
}
