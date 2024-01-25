import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../../../../data/models/refinery.dart';
import 'edit_form_widget.dart';

class EditRefineryScreen extends StatelessWidget {
  final Refinery refinery;

  EditRefineryScreen({required this.refinery})
      : super(key: ApplicationKeys.listRefineriesScreen);
  final refineryEditFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).edit_refinery),
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
            key: refineryEditFormKey,
            child: Column(
              children: <Widget>[
                RefineryEditFormName(refinery: refinery),
                RefineryEditFormDescription(refinery: refinery),
                RefineryEditFormActive(refinery: refinery),
                RefineryEditFormPrice(refinery: refinery, refineryEditFormKey: refineryEditFormKey),
                RefineryEditFormPriceWithVat(refinery: refinery, refineryEditFormKey: refineryEditFormKey),
                SizedBox(height: 20),
                RefineryEditSubmitButton(context,
                    refineryEditFormKey: refineryEditFormKey,
                    refinery: refinery),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
