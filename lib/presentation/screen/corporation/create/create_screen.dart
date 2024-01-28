import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../bloc/corporation_bloc.dart';
import 'create_form_field_widget.dart';

class CreateCorporationScreen extends StatelessWidget {
  CreateCorporationScreen() : super(key: ApplicationKeys.createCorporationScreen);
  final createCorporationFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<CorporationBloc>(context).add(CorporationEvent());
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).create_corporation),
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
            key: createCorporationFormKey,
            child: Column(
              children: <Widget>[
                CorporationCreateFormName(corporationFormKey: createCorporationFormKey),
                CorporationCreateFormDescription(corporationFormKey: createCorporationFormKey),
                CorporationCreateFormActive(corporationFormKey: createCorporationFormKey),
                SizedBox(height: 20),
                CorporationCreateFormSubmitButton(context, createCorporationFormKey: createCorporationFormKey)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
