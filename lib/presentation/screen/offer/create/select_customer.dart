import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';

import '../../../../utils/app_constants.dart';
import '../../customer/bloc/customer_bloc.dart';
import 'create_offer_screen.dart';

class CreateOfferWithSelectCustomerScreen extends StatelessWidget {
  CreateOfferWithSelectCustomerScreen()
      : super(key: ApplicationKeys.createOfferScreen);
  final createOfferFormKey = GlobalKey<FormBuilderState>();
  final headerStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<CustomerBloc>(context).add(CustomerSearch(''));
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).create_offer),
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
        _headerTable(context),
        BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, state) {
            if (state is CustomerSearchSuccessState) {
              return ListView.builder(
                itemCount: state.customerList.length,
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
                            flex: 5,
                            child: Text(
                                state.customerList[index].name.toString(),
                                textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                                state.customerList[index].cariKodu.toString(),
                                textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                                state.customerList[index].phone.toString() == "null"
                                    ? "-"
                                    : state.customerList[index].phone.toString(),
                                textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                                state.customerList[index].vatNo.toString() == "null"
                                    ? "-"
                                    : state.customerList[index].vatNo.toString(),
                                textAlign: TextAlign.left),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                                state.customerList[index].salesPerson
                                            .toString() ==
                                        "null"
                                    ? "-"
                                    : state
                                        .customerList[index].salesPerson!.name
                                        .toString(),
                                textAlign: TextAlign.left),
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
                                    builder: (context) =>
                                        CreateOfferScreen(customer: state.customerList[index],),
                                  ),
                                ).then((value) {});
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

  Padding _headerTable(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
      child: Row(
        children: [
          Expanded(
            flex:5,
            child: Text(S.of(context).name, textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(S.of(context).cari_kod, textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child:
                Text(S.of(context).phone_number, textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(S.of(context).tax_number.toString(), textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(S.of(context).plasiyer, textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 1,
            child: Text("",
                textAlign: TextAlign.center, style: headerStyle),
          ),
        ],
      ),
    );
  }

  Widget _tableSearch(
      double min, double max, double maxWidth, BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 30, 10),
      child: FormBuilder(
          key: createOfferFormKey,
          child: Row(
            children: <Widget>[
              Container(
                width: 200,
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
              SizedBox(width: 10),
              _findButton(context),
            ],
          ),
        ),
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

  _findButton(BuildContext context) {
    return Container(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Text(S.of(context).find),
        onPressed: () {
          if (createOfferFormKey.currentState!.saveAndValidate()) {
            BlocProvider.of<CustomerBloc>(context).add(
              CustomerSearch(
                  createOfferFormKey.currentState!.fields['name']?.value ?? ""),
            );
          }
        },
      ),
    );
  }
}
