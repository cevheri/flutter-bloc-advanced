import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/language_selection_dialog.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes_constants.dart';
import '../../generated/l10n.dart';

/// AppBar actions for quick access: theme toggle, language, and account.
class TopActionsWidget extends StatelessWidget {
  const TopActionsWidget({super.key});

  void _toggleTheme(BuildContext context) {
    final mode = AdaptiveTheme.of(context).mode;
    if (mode.isDark) {
      AdaptiveTheme.of(context).setLight();
    } else {
      AdaptiveTheme.of(context).setDark();
    }
  }

  Future<void> _changeLanguage(BuildContext context) async {
    // LanguageSelectionDialog updates LanguageNotifier; no need to use context after await
    await LanguageSelectionDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: s.theme,
          icon: Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          ),
          onPressed: () => _toggleTheme(context),
        ),
        IconButton(
          tooltip: s.language,
          icon: const Icon(Icons.language_outlined),
          onPressed: () => _changeLanguage(context),
        ),
        IconButton(
          tooltip: s.account,
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.go(ApplicationRoutesConstants.account),
        ),
      ],
    );
  }
}
