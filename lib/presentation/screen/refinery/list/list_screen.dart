//ListRefineryScreen

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../bloc/refinery_bloc.dart';
import '../edit/edit_screen.dart';

class ListRefineriesScreen extends StatelessWidget {
  ListRefineriesScreen() : super(key: ApplicationKeys.listRefineriesScreen);
  final listRefineriesFormKey = GlobalKey<FormBuilderState>();

  final headerStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<RefineryBloc>(context).add(RefinerySearch());
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).list_refinery),
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
        _tableHeader(context),
        BlocBuilder<RefineryBloc, RefineryState>(
          builder: (context, state) {
            if (state is RefinerySearchSuccessState) {
              return ListView.builder(
                itemCount: state.refineryList.length,
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                    child: Column(
                      children: [
                        Container(
                          height: 50,
                          decoration: buildTableRowDecoration(index, context),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                    state.refineryList[index].id.toString(),
                                    textAlign: TextAlign.left),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                    state.refineryList[index].name ?? "",
                                    textAlign: TextAlign.left),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                    state.refineryList[index].description ?? "",
                                    textAlign: TextAlign.left),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                    state.refineryList[index].price.toString(),
                                    textAlign: TextAlign.left),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                    state.refineryList[index].priceWithVat
                                        .toString(),
                                    textAlign: TextAlign.left),
                              ),
                              Expanded(
                                flex: 1,
                                child: buildActiveItem(state, index),
                              ),
                              Expanded(
                                flex: 1,
                                child: buildIconButton(context, state, index),
                              ),
                            ],
                          ),
                        ),
                        //Divider(height: 1, color: Colors.grey),
                      ],
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

  // circle or edit icon button
  IconButton buildIconButton(
      BuildContext context, RefinerySearchSuccessState state, int index) {
    return IconButton(
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
            builder: (context) => EditRefineryScreen(
              refinery: state.refineryList[index],
            ),
          ),
        ).then((value) {
          if (listRefineriesFormKey.currentState!.saveAndValidate()) {
            BlocProvider.of<RefineryBloc>(context).add(RefinerySearch());
          }
        });
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

  Switch buildActiveItem(RefinerySearchSuccessState state, int index) {
    return Switch(
      value: state.refineryList[index].active!,
      onChanged: (value) {
        // ignore: unnecessary_statements
        value;
      },
    );
  }


  Padding _tableHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(S.of(context).id,
                    textAlign: TextAlign.left, style: headerStyle),
              ),
              Expanded(
                flex: 3,
                child: Text(S.of(context).name,
                    textAlign: TextAlign.left, style: headerStyle),
              ),
              Expanded(
                flex: 3,
                child: Text(S.of(context).refineries_description,
                    textAlign: TextAlign.left, style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(S.of(context).price,
                    textAlign: TextAlign.left, style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(S.of(context).price_with_vat,
                    textAlign: TextAlign.left, style: headerStyle),
              ),
              Expanded(
                flex: 1,
                child: Text(S.of(context).active,
                    textAlign: TextAlign.center, style: headerStyle),
              ),
              Expanded(
                flex: 1,
                child: Text("", textAlign: TextAlign.right, style: headerStyle),
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(
            height: 2,
            color: Colors.grey,
            thickness: 1.5,
          ),
        ],
      ),
    );
  }
}
