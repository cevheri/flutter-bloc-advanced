import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/shared/widgets/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_avatar.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart' show AppComponentSize;
import 'package:go_router/go_router.dart';

import 'breadcrumb_widget.dart';

/// Top bar — h-12, border-b, px-4, flex items-center.
class TopBarWidget extends StatelessWidget {
  final String? title;
  final VoidCallback? onMenuTap;

  const TopBarWidget({super.key, this.title, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 48, // h-12
      padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          if (onMenuTap != null)
            IconButton(
              icon: const Icon(Icons.menu, size: 16),
              onPressed: onMenuTap,
              visualDensity: VisualDensity.compact,
            ),
          if (title != null) ...[
            const SizedBox(width: 8),
            // Takes the width that the menu button and the user menu leave, and is shortened when that is too little.
            Expanded(
              child: Text(
                title!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Expanded(child: BreadcrumbWidget()),
          _buildUserMenu(context),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        final name = state.data?.firstName ?? '';
        final initials = _getInitials(state.data?.firstName, state.data?.lastName);

        return PopupMenuButton<String>(
          offset: const Offset(0, 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAvatar(initials: initials, size: AppComponentSize.sm),
              const SizedBox(width: 8),
              // Beside a page title, which only the phone layout shows, a long name is shortened so that it leaves
              // room for the title. Beside the breadcrumb it is shown in full.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: title != null ? 120 : double.infinity),
                child: Text(
                  name,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, size: 14, color: cs.onSurfaceVariant),
            ],
          ),
          onSelected: (value) => _onMenuSelected(context, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'account',
              height: 32,
              child: Row(
                children: [
                  Icon(Icons.person_outlined, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text('Account', style: tt.bodySmall),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              height: 32,
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text('Settings', style: tt.bodySmall),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem(
              value: 'logout',
              height: 32,
              child: Row(
                children: [
                  Icon(Icons.logout, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text('Logout', style: tt.bodySmall),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _onMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'account':
        context.go(ApplicationRoutesConstants.account);
        break;
      case 'settings':
        context.go(ApplicationRoutesConstants.settings);
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await ConfirmationDialog.show(context: context, type: DialogType.logout) ?? false;
    if (!shouldLogout || !context.mounted) return;
    // Route through MenuBloc.Logout so the same code path that the
    // sidebar uses fires — LoginRepository.logout wipes BOTH secure
    // storage (JWT + refreshToken) and AppLocalStorage. Then AWAIT a
    // terminal state before navigating: navigating immediately would
    // race the async logout work and (with the router's
    // "authenticated user on public route → home" rule) momentarily
    // bounce back to home until SessionCubit catches up.
    final menuBloc = context.read<MenuBloc>();
    menuBloc.add(Logout());
    await menuBloc.stream.firstWhere((s) => s.isLogout || s.status == MenuStateStatus.error);
    if (!context.mounted) return;
    if (menuBloc.state.isLogout) {
      context.go(ApplicationRoutesConstants.login);
    }
    // On failure, stay where we are — caller will see the error state
    // via the MenuBloc stream and can surface a toast if desired.
  }

  String _getInitials(String? first, String? last) {
    final f = first?.isNotEmpty == true ? first![0].toUpperCase() : '';
    final l = last?.isNotEmpty == true ? last![0].toUpperCase() : '';
    return '$f$l';
  }
}
