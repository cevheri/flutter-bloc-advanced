import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/language_selection_dialog.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes_constants.dart';
import '../../generated/l10n.dart';
import '../common_blocs/theme/theme_bloc.dart';

/// AppBar actions for quick access: theme toggle, language, and account.
class TopActionsWidget extends StatelessWidget {
  const TopActionsWidget({super.key});

  void _toggleTheme(BuildContext context) {
    context.read<ThemeBloc>().add(const ToggleBrightness());
  }

  Future<void> _changeLanguage(BuildContext context) async {
    // LanguageSelectionDialog updates LanguageNotifier; no need to use context after await
    await LanguageSelectionDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = colorScheme.primaryContainer;
    final iconColor = colorScheme.onPrimaryContainer;

    IconButton buildIconButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
      double? size,
      Color? customBackgroundColor,
      Color? customIconColor,
    }) {
      return IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: customIconColor ?? iconColor, size: size),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: customBackgroundColor ?? backgroundColor,
          shape: const CircleBorder(),
          iconSize: size ?? 20,
          padding: const EdgeInsets.all(8),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildIconButton(
          tooltip: s.theme,
          icon: isDark ? Icons.dark_mode : Icons.light_mode,
          onPressed: () => _toggleTheme(context),
        ),
        const SizedBox(width: 10),
        buildIconButton(
          tooltip: s.language,
          icon: Icons.account_balance,
          size: 22,  
          onPressed: () => _changeLanguage(context),
        ),
        const SizedBox(width: 10),
        buildIconButton(
          tooltip: s.account,
          icon: Icons.person,
          onPressed: () => context.go(ApplicationRoutesConstants.account),
        ),
        const SizedBox(width:50),
      ],
    );
  }
}
