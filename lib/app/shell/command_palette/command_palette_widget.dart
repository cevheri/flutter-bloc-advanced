import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_radius.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:go_router/go_router.dart';

/// [text] in lower case for a search in [language]. String.toLowerCase follows English, where I is the capital of i;
/// in Turkish I is the capital of ı and İ that of i.
String _foldCase(String text, String language) =>
    language == 'tr' ? text.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase() : text.toLowerCase();

/// Command palette entry.
class _CommandEntry {
  final String label;
  final String? description;
  final IconData icon;
  final String route;

  const _CommandEntry({required this.label, this.description, required this.icon, required this.route});
}

/// All available commands for navigation, in the language of [l10n]. Change password is offered only with
/// [passwordSignIn]: in an `oidc` build the identity provider owns the password.
List<_CommandEntry> _commands(S l10n, {required bool passwordSignIn}) => [
  _CommandEntry(
    label: l10n.dashboard,
    description: l10n.command_palette_home_description,
    icon: Icons.dashboard_outlined,
    route: ApplicationRoutesConstants.home,
  ),
  _CommandEntry(
    label: l10n.users,
    description: l10n.command_palette_users_description,
    icon: Icons.people_outline,
    route: ApplicationRoutesConstants.userList,
  ),
  _CommandEntry(
    label: l10n.new_user,
    description: l10n.command_palette_new_user_description,
    icon: Icons.person_add_outlined,
    route: ApplicationRoutesConstants.userNew,
  ),
  _CommandEntry(
    label: l10n.account,
    description: l10n.command_palette_account_description,
    icon: Icons.person_outline,
    route: ApplicationRoutesConstants.account,
  ),
  _CommandEntry(
    label: l10n.settings,
    description: l10n.command_palette_settings_description,
    icon: Icons.settings_outlined,
    route: ApplicationRoutesConstants.settings,
  ),
  if (passwordSignIn)
    _CommandEntry(
      label: l10n.change_password,
      description: l10n.command_palette_change_password_description,
      icon: Icons.lock_outline,
      route: ApplicationRoutesConstants.changePassword,
    ),
];

/// Keyboard shortcut wrapper that listens for Ctrl+K / Cmd+K to open the command palette.
class CommandPaletteShortcut extends StatelessWidget {
  final Widget child;
  const CommandPaletteShortcut({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const _OpenCommandPaletteIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const _OpenCommandPaletteIntent(),
      },
      child: Actions(
        actions: {
          _OpenCommandPaletteIntent: CallbackAction<_OpenCommandPaletteIntent>(
            onInvoke: (_) {
              CommandPalette.show(context);
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}

/// Full-screen command palette overlay.
class CommandPalette {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _CommandPaletteDialog(navigatorContext: context),
    );
  }
}

class _CommandPaletteDialog extends StatefulWidget {
  final BuildContext navigatorContext;
  const _CommandPaletteDialog({required this.navigatorContext});

  @override
  State<_CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<_CommandPaletteDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    setState(() {
      _query = query;
      _selectedIndex = 0;
    });
  }

  void _onSelect(_CommandEntry entry) {
    Navigator.of(context).pop();
    GoRouter.of(widget.navigatorContext).go(entry.route);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Filtered in build, so the search matches the commands in the language the user reads.
    final language = Localizations.localeOf(context).languageCode;
    final query = _foldCase(_query, language);
    final commands = _commands(S.of(context), passwordSignIn: context.read<AuthMode>() is JwtAuthMode);
    final filtered = commands.where((c) {
      return _foldCase(c.label, language).contains(query) ||
          (c.description != null && _foldCase(c.description!, language).contains(query));
    }).toList();

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() => _selectedIndex = (_selectedIndex + 1).clamp(0, filtered.length - 1));
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() => _selectedIndex = (_selectedIndex - 1).clamp(0, filtered.length - 1));
          } else if (event.logicalKey == LogicalKeyboardKey.enter && filtered.isNotEmpty) {
            _onSelect(filtered[_selectedIndex]);
          }
        }
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 400),
          child: Material(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            elevation: 8,
            color: colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search input
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onQueryChanged,
                    decoration: InputDecoration(
                      hintText: S.of(context).command_palette_hint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Chip(
                          label: Text('ESC', style: textTheme.labelSmall),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                Divider(height: 1, color: colorScheme.outlineVariant),
                // Results
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      S.of(context).command_palette_no_results,
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        final isSelected = index == _selectedIndex;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: colorScheme.primaryContainer.withAlpha(60),
                          leading: Icon(
                            entry.icon,
                            size: 20,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            entry.label,
                            style: textTheme.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.w600 : null),
                          ),
                          subtitle: entry.description != null
                              ? Text(
                                  entry.description!,
                                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.keyboard_return, size: 16, color: colorScheme.onSurfaceVariant)
                              : null,
                          onTap: () => _onSelect(entry),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
