import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../../../../data/models/corporation.dart';
import '../bloc/corporation_maturity_bloc.dart';
import 'edit_form_widget.dart';

class EditCorporationMaturityScreen extends StatelessWidget {
  final Corporation corporation;

  EditCorporationMaturityScreen({required this.corporation})
      : super(key: ApplicationKeys.listCorporationsScreen);
  final corporationMaturityEditFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<CorporationMaturityBloc>(context)
        .add(CorporationMaturityLoad(id: corporation.id!));
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).edit_corporation_maturity),
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

  Widget layoutBody(
      BuildContext context, double min, double max, double maxWidth) {
    return FormBuilder(
      key: corporationMaturityEditFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          CorporationMaturityEditForm(
              corporation: corporation,
              formKey: corporationMaturityEditFormKey),
          ListView.builder(
            itemBuilder: (context, index) {
              return SizedBox(height: 20);
            },
          ),
        ],
      ),
    );
  }
}
