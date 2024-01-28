import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../data/models/station.dart';
import '../../../../data/models/station_maturity.dart';
import '../../../../generated/l10n.dart';
import '../../../../utils/message.dart';
import '../bloc/station_maturity_bloc.dart';
import '../station_maturity_const.dart';

class StationMaturityEditForm extends StatelessWidget {
  final Station station;
  final GlobalKey<FormBuilderState> formKey;

  const StationMaturityEditForm({super.key, required this.station, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationMaturityBloc, StationMaturityState>(
      builder: (context, state) {
        if (state is StationMaturityLoadSuccessState && state.stationMaturity.isNotEmpty) {
          state.stationMaturity.sort((a, b) => a.maturity!.compareTo(b.maturity!));
          return Column(
            children: [
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
                child: SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text("*", textAlign: TextAlign.left),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(station.corporation?.name ?? "", textAlign: TextAlign.left),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(station.name ?? "", textAlign: TextAlign.left),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: FormBuilderDropdown(
                            alignment: Alignment.centerLeft,
                            name: "sMaturity",
                            decoration: InputDecoration(
                              labelText: S.of(context).maturity,
                              border: InputBorder.none,
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(errorText: S.of(context).required_maturity),
                            ]),
                            items: ConstStationMaturity.maturityRemainderList
                                .map((e) => DropdownMenuItem(
                                      value: e.type,
                                      child: Text(e.name ?? ""),
                                    ))
                                .toList(),
                            onChanged: (value) {},
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: FormBuilderTextField(
                            name: 'sMaturityRate',
                            decoration: InputDecoration(
                              labelText: S.of(context).rate,
                              border: InputBorder.none,
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(errorText: S.of(context).required_rate),
                              FormBuilderValidators.numeric(errorText: S.of(context).required_rate),
                            ]),
                            initialValue: "",
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          alignment: Alignment.centerRight,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onPressed: () {
                            if (formKey.currentState!.saveAndValidate()) {
                              BlocProvider.of<StationMaturityBloc>(context).add(StationMaturityCreate(
                                  stationMaturity: StationMaturity(
                                maturity: int.parse(formKey.currentState!.fields['sMaturity']!.value.toString()),
                                rate: double.parse(formKey.currentState!.fields['sMaturityRate']!.value.toString()),
                                cost: 0,
                                station: station,
                              )));
                            }
                          },
                          icon: Icon(Icons.create),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListView.builder(
                itemCount: state.stationMaturity.length,
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index < state.stationMaturity.length) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                      child: Container(
                        height: 50,
                        decoration: buildTableRowDecoration(index, context),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(state.stationMaturity[index].id.toString(), textAlign: TextAlign.left),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(station.corporation?.name ?? "", textAlign: TextAlign.left),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(state.stationMaturity[index].station?.name ?? "", textAlign: TextAlign.left),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                  state.stationMaturity[index].maturity == -1
                                      ? "Kredi Kartı"
                                      : "${state.stationMaturity[index].maturity.toString()} Gün",
                                  textAlign: TextAlign.left),
                            ),
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: FormBuilderTextField(
                                  name: 'sMaturityGetRate${state.stationMaturity[index].id}',
                                  decoration: InputDecoration(
                                    labelText: S.of(context).rate,
                                    border: InputBorder.none,
                                  ),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(errorText: S.of(context).required_rate),
                                    FormBuilderValidators.numeric(errorText: S.of(context).required_rate),
                                  ]),
                                  initialValue: state.stationMaturity[index].rate?.toString(),
                                ),
                              ),
                            ),
                            IconButton(
                              alignment: Alignment.centerRight,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onPressed: () {
                                StationMaturity cacheStationMaturity = StationMaturity(
                                  id: state.stationMaturity[index].id,
                                  maturity: state.stationMaturity[index].maturity,
                                  rate: state.stationMaturity[index].rate,
                                  cost: 0,
                                  station: station,
                                );
                                StationMaturity newStationMaturity = StationMaturity(
                                  id: state.stationMaturity[index].id,
                                  maturity: state.stationMaturity[index].maturity,
                                  rate: double.parse(
                                      formKey.currentState!.fields['sMaturityGetRate${state.stationMaturity[index].id}']!.value.toString()),
                                  cost: 0,
                                  station: station,
                                );
                                if (cacheStationMaturity != newStationMaturity) {
                                  BlocProvider.of<StationMaturityBloc>(context)
                                      .add(StationMaturityUpdate(stationMaturity: newStationMaturity));
                                } else {
                                  Message.errorMessage(context: context, title: S.of(context).change_nothing, content: "");
                                }
                              },
                              icon: Icon(Icons.save_as_outlined),
                            ),
                            Container(
                              margin: EdgeInsets.all(5),
                              child: IconButton(
                                alignment: Alignment.centerRight,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(S.of(context).delete_confirmation),
                                      actions: [
                                        TextButton(
                                          child: Text(S.of(context).cancel),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text(S.of(context).delete),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            BlocProvider.of<StationMaturityBloc>(context)
                                                .add(StationMaturityDelete(id: state.stationMaturity[index].id!));
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: Icon(Icons.delete),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Padding(
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
                              child: Text("*", textAlign: TextAlign.center),
                            ),
                            Expanded(
                              child: Text(station.corporation?.name ?? "", textAlign: TextAlign.center),
                            ),
                            Expanded(
                              child: Text(station.name ?? "", textAlign: TextAlign.center),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: FormBuilderDropdown(
                                  name: "sMaturity",
                                  decoration: InputDecoration(
                                    labelText: S.of(context).maturity,
                                    border: InputBorder.none,
                                  ),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(errorText: S.of(context).required_maturity),
                                  ]),
                                  items: ConstStationMaturity.maturityRemainderList
                                      .map((e) => DropdownMenuItem(
                                            value: e.type,
                                            child: Text(e.name ?? ""),
                                          ))
                                      .toList(),
                                  onChanged: (value) {},
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: FormBuilderTextField(
                                  name: 'sMaturityRate',
                                  decoration: InputDecoration(
                                    labelText: S.of(context).rate,
                                    border: InputBorder.none,
                                  ),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(errorText: S.of(context).required_rate),
                                    FormBuilderValidators.numeric(errorText: S.of(context).required_rate),
                                  ]),
                                  initialValue: "",
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(),
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                margin: EdgeInsets.all(5),
                                child: TextButton.icon(
                                  onPressed: () {
                                    if (formKey.currentState!.saveAndValidate()) {
                                      BlocProvider.of<StationMaturityBloc>(context).add(StationMaturityCreate(
                                          stationMaturity: StationMaturity(
                                        maturity: int.parse(formKey.currentState!.fields['sMaturity']!.value.toString()),
                                        rate: double.parse(formKey.currentState!.fields['sMaturityRate']!.value.toString()),
                                        cost: 0,
                                        station: station,
                                      )));
                                    }
                                  },
                                  icon: Icon(Icons.create, color: Colors.white),
                                  label: Text(S.of(context).create, style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        } else {
          return Column(
            children: [
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
                child: SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text("*", textAlign: TextAlign.left),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(station.corporation?.name ?? "", textAlign: TextAlign.left),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(station.name ?? "", textAlign: TextAlign.left),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: FormBuilderDropdown(
                            alignment: Alignment.centerLeft,
                            name: "sMaturity",
                            decoration: InputDecoration(
                              labelText: S.of(context).maturity,
                              border: InputBorder.none,
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(errorText: S.of(context).required_maturity),
                            ]),
                            items: ConstStationMaturity.maturityRemainderList
                                .map((e) => DropdownMenuItem(
                                      value: e.type,
                                      child: Text(e.name ?? ""),
                                    ))
                                .toList(),
                            onChanged: (value) {},
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: FormBuilderTextField(
                            name: 'sMaturityRate',
                            decoration: InputDecoration(
                              labelText: S.of(context).rate,
                              border: InputBorder.none,
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(errorText: S.of(context).required_rate),
                              FormBuilderValidators.numeric(errorText: S.of(context).required_rate),
                            ]),
                            initialValue: "",
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          alignment: Alignment.centerRight,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onPressed: () {
                            if (formKey.currentState!.saveAndValidate()) {
                              BlocProvider.of<StationMaturityBloc>(context).add(StationMaturityCreate(
                                  stationMaturity: StationMaturity(
                                maturity: int.parse(formKey.currentState!.fields['sMaturity']!.value.toString()),
                                rate: double.parse(formKey.currentState!.fields['sMaturityRate']!.value.toString()),
                                cost: 0,
                                station: station,
                              )));
                            }
                          },
                          icon: Icon(Icons.create),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      },
      buildWhen: (previous, current) {
        if (current is StationMaturityLoadSuccessState) {
          return true;
        }
        if (current is StationMaturityDeleteSuccessState ||
            current is StationMaturityCreateSuccessState ||
            current is StationMaturityUpdateSuccessState) {
          BlocProvider.of<StationMaturityBloc>(context).add(StationMaturityLoad(id: station.id!));
          return true;
        }
        return previous != current;
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
}
