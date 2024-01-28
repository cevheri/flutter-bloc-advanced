import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../../../../data/models/corporation.dart';
import 'edit_form_widget.dart';

class EditCorporationScreen extends StatelessWidget {
  final Corporation corporation;

  EditCorporationScreen({required this.corporation})
      : super(key: ApplicationKeys.listCorporationScreen);
  final corporationEditFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).edit_corporation),
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
            key: corporationEditFormKey,
            child: Column(
              children: <Widget>[
                CorporationEditFormName(corporation: corporation),
                CorporationEditFormDescription(corporation: corporation),
                CorporationEditFormActive(corporation: corporation),
                SizedBox(height: 20),
                CorporationEditSubmitButton(context,
                    corporationEditFormKey: corporationEditFormKey,
                    corporation: corporation),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


