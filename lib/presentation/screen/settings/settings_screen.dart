import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/language_selection_dialog.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/l10n.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final _settingsFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(context), body: _buildBody(context));
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).settings),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => AppRouter().push(context, ApplicationRoutesConstants.home),
      ),
    );
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

  FilledButton _buildChangePasswordButton(BuildContext context) {
    return FilledButton(
      key: settingsChangePasswordButtonKey,
      onPressed: () => context.go(ApplicationRoutesConstants.changePassword),
      child: Text(S.of(context).change_password, textAlign: TextAlign.center),
    );
  }

  FilledButton _buildChangeLanguageButton(BuildContext context) {
    return FilledButton.tonal(
      key: settingsChangeLanguageButtonKey,
      onPressed: () => LanguageSelectionDialog.show(context),
      child: Text(S.of(context).language_select, textAlign: TextAlign.center),
    );
  }

  FilledButton _buildLogoutButton(BuildContext context) {
    return FilledButton(
      key: settingsLogoutButtonKey,
      onPressed: () => _handleLogout(context),
      child: Text(S.of(context).logout, textAlign: TextAlign.center),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await ConfirmationDialog.show(context: context, type: DialogType.logout) ?? false;

    if (shouldLogout && context.mounted) {
      AppLocalStorage().clear();
      context.go(ApplicationRoutesConstants.login);
    }
  }
}
