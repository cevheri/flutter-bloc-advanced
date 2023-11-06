
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../configuration/app_keys.dart';
import '../../../configuration/routes.dart';
import '../../common_blocs/account/account_bloc.dart';

class AccountsScreen extends StatelessWidget {
  AccountsScreen() : super(key: ApplicationKeys.accountsScreen);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  List<DropdownMenuItem<String>> createDropdownLanguageItems(Map<String, String> languages) {
    return languages.keys
        .map<DropdownMenuItem<String>>(
          (String key) => DropdownMenuItem<String>(
            value: key,
            child: Text(languages[key]!),
          ),
        )
        .toList();
  }

  submit(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(builder: (context, state) {
      return ElevatedButton(
        onPressed: () {
          //context.read<SettingsBloc>().add(SaveSettings()),
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Center(child: Text("Kaydet")),
        ),
      );
    });
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text("Hesaplar"),
    );
  }

  _buildBody(BuildContext context) {
    return FormBuilder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, ApplicationRoutes.changePassword);
              },
              child: Text(
                "Yeni Hesap oluştur",
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, ApplicationRoutes.changePassword);
              },
              child: Text(
                "Oluşturulmuş hesaplar",
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
