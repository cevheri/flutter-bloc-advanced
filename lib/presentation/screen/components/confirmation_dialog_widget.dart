import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:go_router/go_router.dart';

/// Defines the different types of confirmation dialogs used in the application.
enum DialogType { unsavedChanges, delete, logout }

/// A reusable confirmation dialog widget that follows Material Design guidelines.
/// Used for showing confirmations, warnings and alerts throughout the application.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final BuildContext parentContext;
  final bool barrierDismissible;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.parentContext,
    this.confirmText,
    this.cancelText,
    this.barrierDismissible = false,
  });

  /// Shows a confirmation dialog with the given parameters.
  /// Returns a Future<bool?> indicating the user's choice.
  static Future<bool?> show({
    required BuildContext context,
    required DialogType type,
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = false,
  }) {
    debugPrint('BEGIN: ConfirmationDialog.show');
    final l10n = S.of(context);

    String title;
    String msg;
    confirmText ??= l10n.yes;
    cancelText ??= l10n.no;

    switch (type) {
      case DialogType.unsavedChanges:
        title = l10n.warning;
        msg = l10n.unsaved_changes;
        break;
      case DialogType.delete:
        title = l10n.warning;
        msg = l10n.delete_confirmation;
        break;
      case DialogType.logout:
        title = l10n.logout;
        msg = l10n.logout_sure;
        break;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => ConfirmationDialog(
        parentContext: context,
        title: title,
        message: msg,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('BEGIN: ConfirmationDialog.build');
    final theme = Theme.of(parentContext);

    var result = AlertDialog(
      title: Text(title, style: theme.textTheme.titleLarge),
      content: Text(message, style: theme.textTheme.bodyMedium),
      actions: [
        TextButton(onPressed: () => context.pop(false), child: Text(cancelText!)),
        FilledButton(onPressed: () => context.pop(true), child: Text(confirmText!)),
      ],
    );
    debugPrint('END: ConfirmationDialog.show');
    return result;
  }
}
