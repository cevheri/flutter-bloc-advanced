import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:go_router/go_router.dart';

enum DialogType { unsavedChanges, delete, logout }

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.parentContext,
    this.confirmText,
    this.cancelText,
    this.barrierDismissible = false,
  });

  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final BuildContext parentContext;
  final bool barrierDismissible;

  static Future<bool?> show({
    required BuildContext context,
    required DialogType type,
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = false,
  }) {
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
    final theme = Theme.of(parentContext);

    return AlertDialog(
      title: Text(title, style: theme.textTheme.titleLarge),
      content: Text(message, style: theme.textTheme.bodyMedium),
      actions: [
        TextButton(onPressed: () => context.pop(false), child: Text(cancelText!)),
        FilledButton(onPressed: () => context.pop(true), child: Text(confirmText!)),
      ],
    );
  }
}
