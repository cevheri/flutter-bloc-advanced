import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_breakpoints.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';

/// Scrollable content wrapper with max-width constraint.
class ContentArea extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ContentArea({super.key, required this.child, this.maxWidth = AppBreakpoints.contentMaxWidth, this.padding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding ?? const EdgeInsets.all(AppSpacing.lg), child: child),
      ),
    );
  }
}
