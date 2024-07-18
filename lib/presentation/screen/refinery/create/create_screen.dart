import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../bloc/refinery_bloc.dart';
import 'create_form_field_widget.dart';

class CreateRefineryScreen extends StatelessWidget {
  CreateRefineryScreen() : super(key: ApplicationKeys.createRefineryScreen);
  final createRefineryFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<RefineryBloc>(context).add(RefineryEvent());
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).create_refinery),
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
            key: createRefineryFormKey,
            child: Column(
              children: <Widget>[
                RefineryCreateFormName(refineryFormKey: createRefineryFormKey),
                RefineryCreateFormDescription(refineryFormKey: createRefineryFormKey),
                RefineryCreateFormPrice(refineryFormKey: createRefineryFormKey),
                RefineryCreateFormPriceWithWat(refineryFormKey: createRefineryFormKey),
                RefineryCreateFormActive(refineryFormKey: createRefineryFormKey),
                SizedBox(height: 20),
                RefineryCreateFormSubmitButton(context, createRefineryFormKey: createRefineryFormKey)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
