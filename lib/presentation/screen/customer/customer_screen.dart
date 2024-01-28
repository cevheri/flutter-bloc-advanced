/*
import 'package:flutter_bloc_advance/configuration/app_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../generated/l10n.dart';
import '../../../utils/app_constants.dart';
import 'bloc/customer_bloc.dart';

class CustomerScreen extends StatelessWidget {
  CustomerScreen() : super(key: ApplicationKeys.customerScreen);
  final listCustomerFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).customers),
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
        Divider(),
        Center(
          child: Container(
            height: 40,
            constraints: BoxConstraints(minWidth: min, maxWidth: max),
            child: FormBuilder(
              key: listCustomerFormKey,
              child: Row(
                children: <Widget>[
                  maxWidth > 900 ? SizedBox(width: 20) : SizedBox(width: 5),
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
                    child: FormBuilderTextField(
                      name: 'name',
                      decoration: InputDecoration(hintText: S.of(context).name),
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                      ],
                      initialValue: "",
                    ),
                  ),
                  maxWidth > 900 ? SizedBox(width: 60) : SizedBox(width: 5),
                  _submitButton(context),
                ],
              ),
            ),
          ),
        ),
        Divider(),
        Padding(
          padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(S.of(context).name, textAlign: TextAlign.center),
              ),
              Expanded(
                child:
                    Text(S.of(context).cari_kod, textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text(S.of(context).phone_number,
                    textAlign: TextAlign.center),
              ),
              Expanded(
                child:
                    Text(S.of(context).tax_number, textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text(S.of(context).sales_person_code,
                    textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text(S.of(context).select_customer,
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, state) {
            if (state is CustomerSearchSuccessState) {
              return ListView.builder(
                itemCount: state.customerList.length,
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemBuilder: (context, index) {
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
                            child: Text(
                                state.customerList[index].name.toString(),
                                textAlign: TextAlign.center),
                          ),
                          Expanded(
                            child: Text(
                                state.customerList[index].cariKodu.toString(),
                                textAlign: TextAlign.center),
                          ),
                          Expanded(
                            child: Text(
                                state.customerList[index].phone.toString(),
                                textAlign: TextAlign.center),
                          ),
                          Expanded(
                            child: Text(
                                state.customerList[index].vatNo.toString(),
                                textAlign: TextAlign.center),
                          ),
                          Expanded(
                            child: Text(
                                state.customerList[index].salesPerson
                                            .toString() ==
                                        "null"
                                    ? "-"
                                    : state
                                        .customerList[index].salesPerson!.name
                                        .toString(),
                                textAlign: TextAlign.center),
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                margin: EdgeInsets.all(5),
                                child: TextButton.icon(
                                  onPressed: () {},
                                  icon: Icon(Icons.content_copy,
                                      color: Colors.white),
                                  label: Text(S.of(context).detail,
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
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

  _submitButton(BuildContext context) {
    return Container(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Text(S.of(context).list_user),
        onPressed: () {
          if (listCustomerFormKey.currentState!.saveAndValidate()) {
            BlocProvider.of<CustomerBloc>(context).add(
              CustomerSearch(
                  listCustomerFormKey.currentState!.fields['name']?.value ??
                      ""),
            );
          }
        },
      ),
    );
  }
}


 */