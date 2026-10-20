import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// A consistent error state placeholder with icon, title, description, and retry.
///
/// The caller gives every text in the app language: the design system has no localizations of its own.
class AppErrorState extends StatelessWidget {
  final String title;
  final String? description;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorState({
    super.key,
    required this.title,
    this.description,
    this.retryLabel,
    this.onRetry,
    this.icon = Icons.error_outline,
  }) : assert(onRetry == null || retryLabel != null, 'AppErrorState shows a retry button only with a retryLabel');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colorScheme.error.withAlpha(179)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(retryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
