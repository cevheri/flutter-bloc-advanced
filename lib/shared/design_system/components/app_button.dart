import 'package:flutter/material.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

/// Button variants following shadcn/ui-inspired design.
enum AppButtonVariant { filled, outlined, text, ghost, destructive, icon }

/// Standard component size.
enum AppComponentSize { sm, md, lg }

/// A composable button that unifies all button patterns across the app.
class AppButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppComponentSize size;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final IconData? trailingIcon;
  final Widget? child;

  const AppButton({
    super.key,
    this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppComponentSize.md,
    this.isLoading = false,
    this.fullWidth = false,
    this.icon,
    this.trailingIcon,
    this.child,
  });

  double get _height {
    switch (size) {
      case AppComponentSize.sm:
        return AppSizes.buttonSm;
      case AppComponentSize.md:
        return AppSizes.buttonMd;
      case AppComponentSize.lg:
        return AppSizes.buttonLg;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppComponentSize.sm:
        return AppSizes.iconSm;
      case AppComponentSize.md:
        return AppSizes.iconMd;
      case AppComponentSize.lg:
        return AppSizes.iconLg;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case AppComponentSize.sm:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs);
      case AppComponentSize.md:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm);
      case AppComponentSize.lg:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveOnPressed = isLoading ? null : onPressed;
    final buttonChild = _buildChild(context);

    Widget button;
    switch (variant) {
      case AppButtonVariant.filled:
        button = FilledButton(onPressed: effectiveOnPressed, style: _filledStyle(colorScheme), child: buttonChild);
        break;
      case AppButtonVariant.outlined:
        button = OutlinedButton(onPressed: effectiveOnPressed, style: _outlinedStyle(colorScheme), child: buttonChild);
        break;
      case AppButtonVariant.text:
        button = TextButton(onPressed: effectiveOnPressed, style: _textStyle(colorScheme), child: buttonChild);
        break;
      case AppButtonVariant.ghost:
        button = TextButton(onPressed: effectiveOnPressed, style: _ghostStyle(colorScheme), child: buttonChild);
        break;
      case AppButtonVariant.destructive:
        button = FilledButton(onPressed: effectiveOnPressed, style: _destructiveStyle(colorScheme), child: buttonChild);
        break;
      case AppButtonVariant.icon:
        button = IconButton(
          onPressed: effectiveOnPressed,
          style: _iconButtonStyle(colorScheme),
          icon: isLoading
              ? SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onSurface),
                )
              : Icon(icon, size: _iconSize),
        );
        return button;
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _buildChild(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (child != null) return child!;

    final loadingColor = variant == AppButtonVariant.filled || variant == AppButtonVariant.destructive
        ? colorScheme.onPrimary
        : colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        if (isLoading)
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: loadingColor),
          )
        else if (icon != null)
          Icon(icon, size: _iconSize),
        if (label != null) Text(label!),
        if (trailingIcon != null && !isLoading) Icon(trailingIcon, size: _iconSize),
      ],
    );
  }

  ButtonStyle _filledStyle(ColorScheme cs) => FilledButton.styleFrom(
    minimumSize: Size(0, _height),
    padding: _padding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  );

  ButtonStyle _outlinedStyle(ColorScheme cs) => OutlinedButton.styleFrom(
    minimumSize: Size(0, _height),
    padding: _padding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  );

  ButtonStyle _textStyle(ColorScheme cs) => TextButton.styleFrom(
    minimumSize: Size(0, _height),
    padding: _padding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  );

  ButtonStyle _ghostStyle(ColorScheme cs) => TextButton.styleFrom(
    minimumSize: Size(0, _height),
    padding: _padding,
    foregroundColor: cs.onSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  );

  ButtonStyle _destructiveStyle(ColorScheme cs) => FilledButton.styleFrom(
    minimumSize: Size(0, _height),
    padding: _padding,
    backgroundColor: cs.error,
    foregroundColor: cs.onError,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  );

  ButtonStyle _iconButtonStyle(ColorScheme cs) => IconButton.styleFrom(
    minimumSize: Size(_height, _height),
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  );
}
