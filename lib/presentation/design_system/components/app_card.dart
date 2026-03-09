import 'package:flutter/material.dart';
import '../tokens/app_durations.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_radius.dart';

/// Card variants.
enum AppCardVariant { elevated, outlined, filled }

/// A composable card component replacing raw Container+BoxDecoration.
/// Supports hover elevation on desktop and tap interactions.
class AppCard extends StatefulWidget {
  final Widget? child;
  final Widget? header;
  final Widget? footer;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    this.child,
    this.header,
    this.footer,
    this.variant = AppCardVariant.outlined,
    this.onTap,
    this.padding,
    this.width,
    this.height,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectivePadding = widget.padding ?? const EdgeInsets.all(AppSpacing.lg);

    Widget content = AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppDurations.easeOut,
      width: widget.width,
      height: widget.height,
      decoration: _decoration(colorScheme),
      child: Padding(
        padding: effectivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.header != null) ...[widget.header!, const SizedBox(height: AppSpacing.md)],
            if (widget.child != null) Flexible(child: widget.child!),
            if (widget.footer != null) ...[const SizedBox(height: AppSpacing.md), widget.footer!],
          ],
        ),
      ),
    );

    if (widget.onTap != null) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(onTap: widget.onTap, child: content),
      );
    } else if (widget.variant == AppCardVariant.elevated || widget.variant == AppCardVariant.outlined) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: content,
      );
    }

    return content;
  }

  BoxDecoration _decoration(ColorScheme cs) {
    switch (widget.variant) {
      case AppCardVariant.elevated:
        return BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withAlpha(_isHovered ? 35 : 20),
              blurRadius: _isHovered ? 12 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        );
      case AppCardVariant.outlined:
        return BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: _isHovered ? cs.outline : cs.outlineVariant),
          boxShadow: _isHovered
              ? [BoxShadow(color: cs.shadow.withAlpha(10), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        );
      case AppCardVariant.filled:
        return BoxDecoration(
          color: _isHovered ? cs.surfaceContainerLow.withAlpha(230) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        );
    }
  }
}
