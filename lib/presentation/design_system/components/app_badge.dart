import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';

/// Badge variants.
enum AppBadgeVariant { filled, secondary, destructive, outline, success, warning }

/// A small status/count indicator label.
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;

  const AppBadge({super.key, required this.label, this.variant = AppBadgeVariant.filled, this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (bg, fg) = _colors(colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: variant == AppBadgeVariant.outline ? Colors.transparent : bg,
        borderRadius: BorderRadius.circular(100),
        border: variant == AppBadgeVariant.outline ? Border.all(color: colorScheme.outline, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          if (icon != null) Icon(icon, size: 12, color: fg),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  (Color bg, Color fg) _colors(ColorScheme cs) {
    switch (variant) {
      case AppBadgeVariant.filled:
        return (cs.primary, cs.onPrimary);
      case AppBadgeVariant.secondary:
        return (cs.secondaryContainer, cs.onSecondaryContainer);
      case AppBadgeVariant.destructive:
        return (cs.error, cs.onError);
      case AppBadgeVariant.outline:
        return (Colors.transparent, cs.onSurface);
      case AppBadgeVariant.success:
        return (const Color(0xFF2E7D32), Colors.white);
      case AppBadgeVariant.warning:
        return (const Color(0xFFF9A825), Colors.black);
    }
  }
}
