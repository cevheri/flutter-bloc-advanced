import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../configuration/routes.dart';
import '../../../generated/l10n.dart';

class LanguageConfirmationDialog extends StatefulWidget {
  const LanguageConfirmationDialog({super.key});

  @override
  State<LanguageConfirmationDialog> createState() =>
      _LanguageConfirmationDialogState();

  static _LanguageConfirmationDialogState? of(BuildContext context) =>
      context.findAncestorStateOfType<_LanguageConfirmationDialogState>();
}

class _LanguageConfirmationDialogState
    extends State<LanguageConfirmationDialog> {
  void setLocale(Locale value) {
    setState(() {
      S.delegate.load(value);
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
            onPressed: () async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              prefs.setString('lang', 'tr');
              LanguageConfirmationDialog.of(context)?.setLocale(
                Locale.fromSubtags(languageCode: 'tr'),
              );
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
              LanguageConfirmationDialog.of(context)?.setLocale(
                Locale.fromSubtags(languageCode: 'en'),
              );
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
