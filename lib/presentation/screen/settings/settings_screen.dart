import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/theme_selection_dialog.dart';
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 16,
                        children: [
                          Text(S.of(context).settings, style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            'Manage your account preferences',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Theme.of(context).colorScheme.outlineVariant),

                          // Account
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(S.of(context).account),
                            subtitle: Text(
                              'View or edit your profile information',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            onTap: () => context.go('${ApplicationRoutesConstants.account}?returnToSettings=true'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),

                          // Theme
                          ListTile(
                            leading: const Icon(Icons.light_mode),
                            title: const Text('Theme'),
                            subtitle: Text(
                              'Choose your preferred theme style',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            onTap: () => ThemeSelectionDialog.show(context),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),

                          // Change password
                          ListTile(
                            key: settingsChangePasswordButtonKey,
                            leading: const Icon(Icons.lock),
                            title: Text(S.of(context).change_password),
                            subtitle: Text(
                              'Update your password securely',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            onTap: () =>
                                context.go('${ApplicationRoutesConstants.changePassword}?returnToSettings=true'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),

                          // Logout (moved up to keep visible in test viewport)
                          ListTile(
                            key: settingsLogoutButtonKey,
                            leading: const Icon(Icons.logout),
                            title: Text(S.of(context).logout),
                            subtitle: Text(
                              'Sign out from this device',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            onTap: () => _handleLogout(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
