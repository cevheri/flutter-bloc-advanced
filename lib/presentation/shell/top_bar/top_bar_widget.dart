import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import '../../design_system/components/app_avatar.dart';
import '../../design_system/components/app_button.dart' show AppComponentSize;
import '../../design_system/tokens/app_spacing.dart';
import 'breadcrumb_widget.dart';

/// The top bar shown across all authenticated pages.
class TopBarWidget extends StatelessWidget {
  final String? title;
  final VoidCallback? onMenuTap;

  const TopBarWidget({super.key, this.title, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          if (onMenuTap != null) IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
          if (title != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(title!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ] else
            const Expanded(child: BreadcrumbWidget()),
          if (title != null) const Spacer(),
          _buildUserMenu(context),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        final name = state.data?.firstName ?? '';
        final initials = _getInitials(state.data?.firstName, state.data?.lastName);

        return PopupMenuButton<String>(
          offset: const Offset(0, 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAvatar(initials: initials, size: AppComponentSize.sm),
              const SizedBox(width: AppSpacing.sm),
              Text(name, style: Theme.of(context).textTheme.bodyMedium),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          onSelected: (value) => _onMenuSelected(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'account',
              child: ListTile(leading: Icon(Icons.person), title: Text('Account')),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(leading: Icon(Icons.logout), title: Text('Logout')),
            ),
          ],
        );
      },
    );
  }

  void _onMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'account':
        AppRouter().push(context, ApplicationRoutesConstants.account);
        break;
      case 'settings':
        AppRouter().push(context, ApplicationRoutesConstants.settings);
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await ConfirmationDialog.show(context: context, type: DialogType.logout) ?? false;
    if (shouldLogout && context.mounted) {
      AppLocalStorage().clear();
      AppRouter().push(context, ApplicationRoutesConstants.login);
    }
  }

  String _getInitials(String? first, String? last) {
    final f = first?.isNotEmpty == true ? first![0].toUpperCase() : '';
    final l = last?.isNotEmpty == true ? last![0].toUpperCase() : '';
    return '$f$l';
  }
}
