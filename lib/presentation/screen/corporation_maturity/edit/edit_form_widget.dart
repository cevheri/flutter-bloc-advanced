import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../data/models/corporation.dart';
import '../../../../data/models/corporation_maturity.dart';
import '../../../../generated/l10n.dart';
import '../../../../utils/message.dart';
import '../bloc/corporation_maturity_bloc.dart';
import '../const.dart';

class CorporationMaturityEditForm extends StatelessWidget {
  final Corporation corporation;
  final GlobalKey<FormBuilderState> formKey;

  const CorporationMaturityEditForm({super.key, required this.corporation, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CorporationMaturityBloc, CorporationMaturityState>(
      builder: (context, state) {
        if (state is CorporationMaturityLoadSuccessState && state.corporationMaturity.isNotEmpty) {
          state.corporationMaturity.sort((a, b) => a.maturity!.compareTo(b.maturity!));
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
                        child: Text(corporation.name ?? "", textAlign: TextAlign.left),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: FormBuilderDropdown(
                            name: "cMaturity",
                            decoration: InputDecoration(
                              labelText: S.of(context).maturity,
                              border: InputBorder.none,
                            ),
                            alignment: Alignment.centerLeft,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(errorText: S.of(context).required_maturity),
                            ]),
                            items: ConstCorporationMaturity.maturityRemainderList
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
                            name: 'cMaturityRate',
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
                      SizedBox(width: 50),
                      IconButton(
                        alignment: Alignment.centerRight,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onPressed: () {
                          if (formKey.currentState!.saveAndValidate()) {
                            BlocProvider.of<CorporationMaturityBloc>(context).add(CorporationMaturityCreate(
                                corporationMaturity: CorporationMaturity(
                              maturity: int.parse(formKey.currentState!.fields['cMaturity']!.value.toString()),
                              rate: double.parse(formKey.currentState!.fields['cMaturityRate']!.value.toString()),
                              corporation: corporation,
                            )));
                          }
                        },
                        icon: Icon(Icons.create),
                      ),
                    ],
                  ),
                ),
              ),
              ListView.builder(
                itemCount: state.corporationMaturity.length,
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
                            child: Text(state.corporationMaturity[index].corporation!.id.toString(), textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(state.corporationMaturity[index].corporation?.name ?? "", textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                                state.corporationMaturity[index].maturity == -1
                                    ? "Kredi Kartı"
                                    : "${state.corporationMaturity[index].maturity.toString()} Gün",
                                textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                              child: FormBuilderTextField(
                                name: 'cMaturityGetRate${state.corporationMaturity[index].id}',
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                decoration: InputDecoration(
                                  labelText: S.of(context).rate,
                                  border: InputBorder.none,
                                ),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(errorText: S.of(context).required_rate),
                                  FormBuilderValidators.numeric(errorText: S.of(context).required_rate),
                                ]),
                                initialValue: state.corporationMaturity[index].rate?.toString(),
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
                              CorporationMaturity cacheCorporationMaturity = CorporationMaturity(
                                id: state.corporationMaturity[index].id,
                                maturity: state.corporationMaturity[index].maturity,
                                rate: state.corporationMaturity[index].rate,
                                corporation: corporation,
                              );
                              CorporationMaturity newCorporationMaturity = CorporationMaturity(
                                id: state.corporationMaturity[index].id,
                                maturity: state.corporationMaturity[index].maturity,
                                rate: double.parse(formKey
                                    .currentState!.fields['cMaturityGetRate${state.corporationMaturity[index].id}']!.value
                                    .toString()),
                                corporation: corporation,
                              );
                              if (cacheCorporationMaturity != newCorporationMaturity) {
                                BlocProvider.of<CorporationMaturityBloc>(context)
                                    .add(CorporationMaturityUpdate(corporationMaturity: newCorporationMaturity));
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
                                          BlocProvider.of<CorporationMaturityBloc>(context)
                                              .add(CorporationMaturityDelete(id: state.corporationMaturity[index].id!));
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
                        child: Text(corporation.name ?? "", textAlign: TextAlign.left),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: FormBuilderDropdown(
                            name: "cMaturity",
                            decoration: InputDecoration(
                              labelText: S.of(context).maturity,
                              border: InputBorder.none,
                            ),
                            alignment: Alignment.centerLeft,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(errorText: S.of(context).required_maturity),
                            ]),
                            items: ConstCorporationMaturity.maturityRemainderList
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
                            name: 'cMaturityRate',
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
                              BlocProvider.of<CorporationMaturityBloc>(context).add(CorporationMaturityCreate(
                                  corporationMaturity: CorporationMaturity(
                                maturity: int.parse(formKey.currentState!.fields['cMaturity']!.value.toString()),
                                rate: double.parse(formKey.currentState!.fields['cMaturityRate']!.value.toString()),
                                corporation: corporation,
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
        if (current is CorporationMaturityLoadSuccessState) {
          return true;
        }
        if (current is CorporationMaturityDeleteSuccessState ||
            current is CorporationMaturityCreateSuccessState ||
            current is CorporationMaturityUpdateSuccessState) {
          BlocProvider.of<CorporationMaturityBloc>(context).add(CorporationMaturityLoad(id: corporation.id!));
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
