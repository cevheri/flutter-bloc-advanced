import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';

/// A themed divider with optional label.
class AppDivider extends StatelessWidget {
  final String? label;
  final double thickness;
  final double verticalPadding;

  const AppDivider({super.key, this.label, this.thickness = 1, this.verticalPadding = AppSpacing.sm});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (label == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Divider(color: colorScheme.outlineVariant, thickness: thickness),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: colorScheme.outlineVariant, thickness: thickness),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              label!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Divider(color: colorScheme.outlineVariant, thickness: thickness),
          ),
        ],
      ),
    );
  }
}
