import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen non-dismissable force update overlay.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, this.storeUrl, this.currentVersion, this.minimumVersion});

  final String? storeUrl;
  final String? currentVersion;
  final String? minimumVersion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                'Update Required',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'A new version is available. Please update to continue using the app.',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (currentVersion != null && minimumVersion != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Current: $currentVersion  •  Required: $minimumVersion',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              if (storeUrl != null)
                AppButton(label: 'Update Now', icon: Icons.open_in_new, onPressed: () => _launchStore(storeUrl!)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchStore(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
