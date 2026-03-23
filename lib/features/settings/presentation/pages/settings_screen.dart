import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_card.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/widgets/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/shared/widgets/theme_selection_dialog.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../generated/l10n.dart';
import '../../../../infrastructure/config/template_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).settings,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Manage your account preferences',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Account section
              _SettingsSection(
                title: S.of(context).account,
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: S.of(context).account,
                    subtitle: 'View or edit your profile information',
                    onTap: () => context.push(ApplicationRoutesConstants.account),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSection(
                title: S.of(context).change_password,
                children: [
                  _SettingsTile(
                    key: settingsChangePasswordButtonKey,
                    icon: Icons.lock_outline,
                    title: S.of(context).change_password,
                    subtitle: 'Update your password securely',
                    onTap: () => context.push(ApplicationRoutesConstants.changePassword),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Appearance section
              _SettingsSection(
                title: 'Appearance',
                children: [
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    subtitle: 'Choose your preferred theme style',
                    onTap: () => ThemeSelectionDialog.show(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Help & Resources section
              _SettingsSection(
                title: S.of(context).help_resources,
                children: [
                  _SettingsTile(
                    key: settingsWebsiteButtonKey,
                    icon: Icons.language,
                    title: S.of(context).website,
                    subtitle: S.of(context).help_resources_subtitle,
                    onTap: () => _launchWebsite(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Danger zone
              _SettingsSection(
                title: S.of(context).logout,
                isDanger: true,
                children: [
                  _SettingsTile(
                    key: settingsLogoutButtonKey,
                    icon: Icons.logout,
                    title: S.of(context).logout,
                    subtitle: 'Sign out from this device',
                    isDanger: true,
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWebsite() async {
    final uri = Uri.parse(TemplateConfig.docsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await ConfirmationDialog.show(context: context, type: DialogType.logout) ?? false;
    if (shouldLogout && context.mounted) {
      AppLocalStorage().clear();
      context.go(ApplicationRoutesConstants.login);
    }
  }
}

/// A grouped settings section with a title and list of tiles.
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDanger;

  const _SettingsSection({required this.title, required this.children, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: isDanger ? colorScheme.error : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppCard(
          variant: isDanger ? AppCardVariant.outlined : AppCardVariant.outlined,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                    color: colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Individual settings tile with icon, title, subtitle, and navigation.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDanger;

  const _SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: Icon(icon, color: isDanger ? colorScheme.error : colorScheme.onSurfaceVariant),
      title: Text(title, style: TextStyle(color: isDanger ? colorScheme.error : null)),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: isDanger ? null : Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
