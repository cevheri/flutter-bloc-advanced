import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';

import '../../../configuration/routes.dart';
import '../../../generated/l10n.dart';
import '../../common_widgets/drawer/drawer_bloc/drawer.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final _settingsFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(context), body: _buildBody(context));
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
        title: Text(S.of(context).settings), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)));
  }

  _buildBody(BuildContext context) {
    return FormBuilder(
      key: _settingsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(height: 20),
          Center(child: SizedBox(width: 150, child: _buildChangePasswordButton(context))),
          const SizedBox(height: 20),
          Center(child: SizedBox(width: 150, child: _buildChangeLanguageButton(context))),
          const SizedBox(height: 20),
          Center(child: SizedBox(width: 150, child: _buildLogoutButton(context))),
        ],
      ),
    );
  }

  ElevatedButton _buildChangePasswordButton(BuildContext context) {
    return ElevatedButton(
      key: settingsChangePasswordButtonKey,
      onPressed: () => Navigator.pushNamed(context, ApplicationRoutes.changePassword),
      child: Text(S.of(context).change_password, textAlign: TextAlign.center),
    );
  }

  ElevatedButton _buildChangeLanguageButton(BuildContext context) {
    return ElevatedButton(
      key: settingsChangeLanguageButtonKey,
      child: Text(S.of(context).language_select, textAlign: TextAlign.center),
      onPressed: () => showDialog(context: context, builder: (context) => const LanguageConfirmationDialog()),
    );
  }

  ElevatedButton _buildLogoutButton(BuildContext context) {
    return ElevatedButton(
      key: settingsLogoutButtonKey,
      child: Text(S.of(context).logout, textAlign: TextAlign.center),
      onPressed: () => showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).logout),
            content: Text(S.of(context).logout_sure),
            actions: [
              TextButton(onPressed: () => onLogout(context), child: Text(S.of(context).yes)),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(S.of(context).no)),
            ],
          );
        },
      ),
    );
  }

  void onLogout(context) {
    BlocProvider.of<DrawerBloc>(context).add(Logout());
    Navigator.pushNamedAndRemoveUntil(context, ApplicationRoutes.login, (route) => false);
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
          style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
          onPressed: () => _setLanguage(context, 'tr'),
          child: Text(S.of(context).turkish, style: const TextStyle(color: Colors.white)),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => _setLanguage(context, 'en'),
          child: Text(S.of(context).english, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _setLanguage(BuildContext context, String langCode) async {
    await AppLocalStorage().save(StorageKeys.language.name, langCode);
    await S.load(Locale(langCode));
    Get.back();
  }
}
