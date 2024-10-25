import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../configuration/routes.dart';
import '../../../generated/l10n.dart';
import '../../common_widgets/drawer/bloc/drawer_bloc.dart';
import 'bloc/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen() : super();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  List<DropdownMenuItem<String>> createDropdownLanguageItems(
      Map<String, String> languages) {
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
        onPressed: () {}, //context.read<SettingsBloc>().add(SaveSettings()),
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
                  Navigator.pushNamed(context, ApplicationRoutes.account);
                },
                child: Text(
                  S.of(context).account,
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
                  Navigator.pushNamed(
                      context, ApplicationRoutes.changePassword);
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
                  themeConfirmationDialog(context);
                },
                child: Text(
                  S.of(context).theme,
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

  Future languageConfirmationDialog(
    BuildContext context,
  ) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(S.of(context).language_select, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () async {
                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                prefs.setString('lang', 'tr');
                S.load(Locale("tr"));
                Navigator.pushNamed(context, ApplicationRoutes.home);
              },
              child: Text(S.of(context).turkish,
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () async {
                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                prefs.setString('lang', 'en');
                S.load(Locale("en"));
                Navigator.pushNamed(context, ApplicationRoutes.home);
              },
              child: Text(S.of(context).english,
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future themeConfirmationDialog(
    BuildContext context,
  ) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).theme, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Switch(
              value: AdaptiveTheme.of(context).mode.isDark,
              onChanged: (value) {
                if (value) {
                  AdaptiveTheme.of(context).setDark();
                } else {
                  AdaptiveTheme.of(context).setLight();
                }
              },
            ),
          ],
        );
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
