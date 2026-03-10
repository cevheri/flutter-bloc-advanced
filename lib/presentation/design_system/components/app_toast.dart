import 'package:flutter/material.dart';
import '../theme/semantic_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_durations.dart';

/// Toast variant determines color and icon.
enum AppToastVariant { success, error, warning, info }

/// Modern overlay-based toast notification replacing SnackBar usage.
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;

  /// Show a toast notification.
  static void show(
    BuildContext context, {
    required AppToastVariant variant,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _AppToastWidget(
        variant: variant,
        message: message,
        title: title,
        duration: duration,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _AppToastWidget extends StatefulWidget {
  final AppToastVariant variant;
  final String message;
  final String? title;
  final Duration duration;
  final VoidCallback onDismiss;

  const _AppToastWidget({
    required this.variant,
    required this.message,
    this.title,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppDurations.normal);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppDurations.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: AppDurations.easeOut));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpacing.lg,
      left: isDesktop ? null : AppSpacing.lg,
      right: isDesktop ? AppSpacing.xl : AppSpacing.lg,
      width: isDesktop ? 380 : null,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(color: Colors.transparent, child: _buildToast(context)),
        ),
      ),
    );
  }

  Widget _buildToast(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = context.semanticColors;
    final (bg, fg, iconData) = _variantStyle(colorScheme, semanticColors);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [BoxShadow(color: colorScheme.shadow.withAlpha(30), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(iconData, color: fg, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
                  ),
                Text(widget.message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: fg.withAlpha(179)),
            onPressed: () {
              _controller.reverse().then((_) {
                if (mounted) widget.onDismiss();
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  (Color bg, Color fg, IconData icon) _variantStyle(ColorScheme cs, SemanticColors sc) {
    switch (widget.variant) {
      case AppToastVariant.success:
        return (sc.successContainer, sc.onSuccessContainer, Icons.check_circle_outline);
      case AppToastVariant.error:
        return (cs.errorContainer, cs.onErrorContainer, Icons.error_outline);
      case AppToastVariant.warning:
        return (sc.warningContainer, sc.onWarningContainer, Icons.warning_amber_outlined);
      case AppToastVariant.info:
        return (sc.infoContainer, sc.onInfoContainer, Icons.info_outline);
    }
  }
}
