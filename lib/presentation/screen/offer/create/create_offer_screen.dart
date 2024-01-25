import 'package:flutter_bloc_advance/data/models/customer.dart';
import 'package:flutter_bloc_advance/presentation/screen/refinery/bloc/refinery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../configuration/app_keys.dart';
import '../../../../../generated/l10n.dart';
import '../../../common_blocs/city/city_bloc.dart';
import '../../corporation/bloc/corporation_bloc.dart';
import 'create_form_widget.dart';

class CreateOfferScreen extends StatelessWidget {
  final Customer customer;

  CreateOfferScreen({required this.customer}) : super(key: ApplicationKeys.createOfferScreen);
  final createOfferFormKey = GlobalKey<FormBuilderState>();
  final headerStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<RefineryBloc>(context).add(RefinerySearch());
    BlocProvider.of<CorporationBloc>(context).add(CorporationSearch());
    BlocProvider.of<CityBloc>(context).add(CityLoadList());
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
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minWidth: 300, maxWidth: 700),
          padding: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: FormBuilder(
            key: createOfferFormKey,
            child: Column(
              children: <Widget>[
                customerDetailTable(context, customer),
                OfferCreateFormSelectRefinery(createOfferFormKey: createOfferFormKey),
                OfferCreateFormSelectCorporation(createOfferFormKey: createOfferFormKey),
                OfferCreateFormSelectStation(createOfferFormKey: createOfferFormKey),
                OfferCreateFormSelectCity(createOfferFormKey: createOfferFormKey),
                OfferCreateFormSelectDistrict(createOfferFormKey: createOfferFormKey),
                OfferCreateFormTransportDistance(createOfferFormKey: createOfferFormKey),
                OfferCreateFormTransportCost(createOfferFormKey: createOfferFormKey),
                OfferCreateFormLitre(createOfferFormKey: createOfferFormKey),
                OfferCreateFormSelectCorporationMaturity(createOfferFormKey: createOfferFormKey),
                OfferCreateFormIncrease(createOfferFormKey: createOfferFormKey),
                OfferCreateFormDescription(createOfferFormKey: createOfferFormKey),
                OfferCreateFormTransportDate(createOfferFormKey: createOfferFormKey),
                SizedBox(height: 20),
                OfferCreateFormSubmitButton(context, createOfferFormKey: createOfferFormKey, customer: customer)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
