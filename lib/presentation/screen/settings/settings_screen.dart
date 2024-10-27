import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../configuration/routes.dart';
import '../../../generated/l10n.dart';
import '../../common_widgets/drawer/drawer_bloc/drawer_bloc.dart';
import 'bloc/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
    return BlocBuilder<SettingsBloc, SettingsState>(builder: (context, state) {
      return ElevatedButton(
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Visibility(
                replacement: CircularProgressIndicator(value: null),
                visible: state.status != SettingsStatus.loaded,
                child: Text(S.of(context).save),
              ),
            )),
        onPressed: () {},
      );
    });
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).settings),
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
            child: SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, ApplicationRoutes.changePassword);
                },
                child: Text(
                  S.of(context).change_password,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () {
                  languageConfirmationDialog(context);
                },
                child: Text(
                  S.of(context).language_select,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () {
                  logOutDialog(context);
                  //Navigator.pushNamed(context, ApplicationRoutes.logout);
                },
                child: Text(
                  S.of(context).logout,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> languageConfirmationDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return const LanguageConfirmationDialog();
      },
    );
  }

  Future logOutDialog(
    BuildContext context,
  ) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).logout),
          content: Text(S.of(context).logout_sure),
          actions: [
            TextButton(
              onPressed: () => onLogout(context),
              child: Text(S.of(context).yes),
            ),
            TextButton(
              onPressed: () => onCancel(context),
              child: Text(S.of(context).no),
            ),
          ],
        );
      },
    );
  }

  void onLogout(context) {
    BlocProvider.of<DrawerBloc>(context).add(Logout());
    Navigator.pushNamed(context, ApplicationRoutes.login);
  }

  void onCancel(context) {
    //pop context
    Navigator.pop(context);
  }
}




class LanguageConfirmationDialog extends StatelessWidget {
  const LanguageConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).language_select, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => _setLanguage(context, 'tr'),
          child: Text(S.of(context).turkish, style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => _setLanguage(context, 'en'),
          child: Text(S.of(context).english, style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _setLanguage(BuildContext context, String langCode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', langCode);
    await S.load(Locale(langCode));
    Get.back();
  }
}

