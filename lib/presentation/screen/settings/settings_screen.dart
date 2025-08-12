import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
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
        onPressed: () =>
            AppRouter().push(context, ApplicationRoutesConstants.home),
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
                        spacing: 8,
                        children: [
                          Text(
                            S.of(context).settings,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Manage your account preferences',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),

                          // Account
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(S.of(context).account),
                            subtitle: Text(
                              'View or edit your profile information',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            onTap: () =>
                                context.go(ApplicationRoutesConstants.account),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),

                          // Theme
                          ListTile(
                            leading: const Icon(Icons.dark_mode_outlined),
                            title: const Text('Theme'),
                            subtitle: Text(
                              'Switch between light and dark',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Light',
                                  icon: const Icon(Icons.light_mode_outlined),
                                  onPressed: () =>
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? null
                                      : AdaptiveTheme.of(context).setLight(),
                                ),
                                IconButton(
                                  tooltip: 'Dark',
                                  icon: const Icon(Icons.dark_mode_outlined),
                                  onPressed: () =>
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? null
                                      : AdaptiveTheme.of(context).setDark(),
                                ),
                              ],
                            ),
                          ),

                          // Change password
                          ListTile(
                            key: settingsChangePasswordButtonKey,
                            leading: const Icon(Icons.lock_reset_outlined),
                            title: Text(S.of(context).change_password),
                            subtitle: Text(
                              'Update your password securely',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            onTap: () => context.go(
                              ApplicationRoutesConstants.changePassword,
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),

                          // Logout (moved up to keep visible in test viewport)
                          ListTile(
                            key: settingsLogoutButtonKey,
                            leading: const Icon(Icons.logout_rounded),
                            title: Text(S.of(context).logout),
                            subtitle: Text(
                              'Sign out from this device',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            onTap: () => _handleLogout(context),
                          ),

                          // Change language
                          ListTile(
                            key: settingsChangeLanguageButtonKey,
                            leading: const Icon(Icons.language_outlined),
                            title: Text(S.of(context).language_select),
                            subtitle: Text(
                              'Switch application language',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            onTap: () => LanguageSelectionDialog.show(context),
                            trailing: const Icon(Icons.chevron_right_rounded),
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
    final shouldLogout =
        await ConfirmationDialog.show(
          context: context,
          type: DialogType.logout,
        ) ??
        false;

    if (shouldLogout && context.mounted) {
      AppLocalStorage().clear();
      context.go(ApplicationRoutesConstants.login);
    }
  }
}
