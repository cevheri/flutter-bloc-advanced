import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/language_notifier.dart';
import 'package:go_router/go_router.dart';

class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (_) => const LanguageSelectionDialog());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = S.of(context);

    return AlertDialog(
      title: Text(l10n.language_select, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          style: TextButton.styleFrom(backgroundColor: theme.colorScheme.primary),
          onPressed: () => _setLanguage(context, 'tr'),
          child: Text(l10n.turkish, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
        ),
        TextButton(
          style: TextButton.styleFrom(backgroundColor: theme.colorScheme.primary),
          onPressed: () => _setLanguage(context, 'en'),
          child: Text(l10n.english, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
        ),
      ],
    );
  }

  Future<void> _setLanguage(BuildContext context, String langCode) async {
    await AppLocalStorage().save(StorageKeys.language.name, langCode);
    await S.load(Locale(langCode));
    LanguageNotifier.current.value = langCode;
    if (context.mounted) {
      context.pop();
    }
  }
}
