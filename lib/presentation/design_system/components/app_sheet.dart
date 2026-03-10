import 'package:flutter/material.dart';
import '../tokens/app_breakpoints.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Shows a responsive sheet: bottom sheet on mobile, side sheet on desktop.
class AppSheet {
  AppSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    double desktopWidth = 400,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (AppBreakpoints.isDesktop(screenWidth)) {
      return _showSideSheet<T>(context: context, child: child, title: title, width: desktopWidth);
    }
    return _showBottomSheet<T>(context: context, child: child, title: title);
  }

  static Future<T?> _showBottomSheet<T>({required BuildContext context, required Widget child, String? title}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }

  static Future<T?> _showSideSheet<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    required double width,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.lg)),
            child: Container(
              width: width,
              height: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.lg)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (title != null) Expanded(child: Text(title, style: Theme.of(ctx).textTheme.titleLarge)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(child: SingleChildScrollView(child: child)),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}
