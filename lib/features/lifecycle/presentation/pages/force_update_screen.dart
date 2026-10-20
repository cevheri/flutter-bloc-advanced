import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/utils/external_link.dart';

/// Full-screen non-dismissable force update overlay.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, this.storeUrl, this.currentVersion, this.minimumVersion});

  static final _log = AppLogger.getLogger('ForceUpdateScreen');

  final String? storeUrl;
  final String? currentVersion;
  final String? minimumVersion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = S.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.system_update, size: 80, color: colorScheme.primary),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.force_update_title,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.force_update_message,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (currentVersion != null && minimumVersion != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.force_update_versions(currentVersion!, minimumVersion!),
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              // The screen cannot be dismissed, so without a store link it tells the user where to update instead.
              if (storeUrl != null)
                AppButton(
                  label: l10n.force_update_button,
                  icon: Icons.open_in_new,
                  onPressed: () => _openStore(context, storeUrl!),
                )
              else
                Text(
                  l10n.force_update_no_store_link,
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the store page that the app config names. Only an https URL with a host is opened: anything else is a
  /// server misconfiguration, and an http link would let the network swap the update for another page.
  Future<void> _openStore(BuildContext context, String storeUrl) async {
    final uri = Uri.tryParse(storeUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _log.error('Rejected store URL from app config: {}', [storeUrl]);
      final message = S.of(context).force_update_store_link_invalid;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    await openExternalLink(context, uri);
  }
}
