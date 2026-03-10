import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// A card container specialized for forms with header/content/footer slots.
class AppFormCard extends StatelessWidget {
  final Widget? header;
  final Widget child;
  final Widget? footer;

  const AppFormCard({super.key, this.header, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
              child: header,
            ),
          Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl), child: child),
          if (footer != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// A semantic field wrapper inspired by shadcn Field primitive.
class AppFormField extends StatelessWidget {
  final String label;
  final String? description;
  final Widget child;
  final String? errorText;

  const AppFormField({super.key, required this.label, required this.child, this.description, this.errorText});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        child,
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(description!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(errorText!, style: tt.bodySmall?.copyWith(color: cs.error)),
        ],
      ],
    );
  }
}

/// Vertical section for grouping related fields.
class AppFormSection extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;

  const AppFormSection({super.key, required this.title, required this.children, this.description});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(description!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    );
  }
}

/// Action row for form footer buttons.
class AppFormActions extends StatelessWidget {
  final Widget secondaryAction;
  final Widget? primaryAction;

  const AppFormActions({super.key, required this.secondaryAction, this.primaryAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        secondaryAction,
        if (primaryAction != null) ...[const SizedBox(width: AppSpacing.sm), primaryAction!],
      ],
    );
  }
}
