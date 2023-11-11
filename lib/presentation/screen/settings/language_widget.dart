



import 'package:flutter/material.dart';

import '../../../configuration/app_keys.dart';
import '../../../configuration/routes.dart';
import '../../../generated/l10n.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen() :super(key: ApplicationKeys.languageScreen);

  @override
  State<LanguageScreen> createState() =>
      _LanguageConfirmationDialogState();
}

class _LanguageConfirmationDialogState
    extends State<LanguageScreen> {
  void setLocale(String value) {
    setState(() {
      Locale(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AlertDialog(
        title: Text(S.of(context).language_select, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              setLocale("tr");
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
            onPressed: () {
              setLocale("en");
              S.load(Locale("en"));
              Navigator.pushNamed(context, ApplicationRoutes.home);
            },
            child: Text(S.of(context).english,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
